require "base64"
require "digest"
require "fileutils"
require "json"
require "open3"
require "openssl"
require "pathname"
require "rubygems/package"
require "tempfile"
require "tmpdir"
require "yaml"
require "zlib"

module IonRegoBundle
  MAX_BUNDLE_BYTES = 10 << 20
  SIGNING_ALGORITHM = "ES256".freeze
  SIGNING_KEY_ID = "default".freeze
  BUNDLE_NAME = "ion-release%d-policy.tar.gz".freeze
  TEST_PUBLIC_KEY_NAME = "TEST-ONLY-ion-release%d-policy-public.pem".freeze

  module_function

  def canonical_paths(release_root)
    root = Pathname.new(File.expand_path(release_root))
    release = release_number(root)
    bundles = root.join("rules/bundles")
    {
      bundle: bundles.join(format(BUNDLE_NAME, release)),
      test_public_key: bundles.join(format(TEST_PUBLIC_KEY_NAME, release))
    }
  end

  def expected_files(release_root)
    root = Pathname.new(File.expand_path(release_root))
    rego_root = root.join("rules/rego")
    errors = []
    files = {}
    Dir.glob(rego_root.join("**/*.rego").to_s).sort.each do |source|
      path = Pathname.new(source)
      relative = path.relative_path_from(rego_root).to_s
      errors << "#{path.relative_path_from(root)}: bundle source must not traverse a symlink" if symlink_in_path?(rego_root, path)
      errors << "#{path.relative_path_from(root)}: test module is not allowed in production sources" if path.basename.to_s.end_with?("_test.rego")
      errors << "#{path.relative_path_from(root)}: executable source file is not allowed" if path.executable?
      files[relative] = path.binread
    end
    errors << "rules/rego: no production modules available for bundling" if files.empty?

    data_root = root.join("rules/data")
    data_path = data_root.join("data.json")
    errors << "rules/data/data.json: required runtime data file is missing" unless data_path.file?
    if data_path.file?
      errors << "rules/data/data.json: bundle source must not traverse a symlink" if symlink_in_path?(data_root, data_path)
      errors << "rules/data/data.json: executable runtime data file is not allowed" if data_path.executable?
      begin
        JSON.parse(data_path.read)
      rescue JSON::ParserError => e
        errors << "rules/data/data.json: invalid JSON: #{e.message}"
      end
      files["data.json"] = data_path.binread
    end
    unexpected_data = Dir.glob(data_root.join("**/*").to_s).select { |path| File.file?(path) && Pathname.new(path) != data_path }
    unexpected_data.sort.each do |path|
      errors << "#{Pathname.new(path).relative_path_from(root)}: unexpected runtime data file"
    end
    [files, errors]
  end

  def build(release_root, opa:, signing_mode:, signing_key: nil, verification_key: nil, write: false, out: $stdout, err: $stderr)
    root = Pathname.new(File.expand_path(release_root))
    files, errors = expected_files(root)
    unless errors.empty?
      errors.each { |message| err.puts "ERROR: #{message}" }
      return false
    end

    Dir.mktmpdir("ion-rego-bundle-") do |temporary|
      temp = Pathname.new(temporary)
      stage = temp.join("stage")
      files.each do |relative, content|
        destination = stage.join(relative)
        destination.dirname.mkpath
        destination.binwrite(content)
      end

      key_paths = prepare_keys(temp, signing_mode, signing_key, verification_key)
      bundle = temp.join("bundle.tar.gz")
      command = [
        opa, "build", "--bundle", ".",
        "--signing-key", key_paths.fetch(:private).to_s,
        "--signing-alg", SIGNING_ALGORITHM,
        "--output", bundle.to_s
      ]
      stdout, stderr, status = Open3.capture3(*command, chdir: stage.to_s)
      unless status.success?
        err.puts "OPA bundle construction failed"
        err.puts stdout unless stdout.empty?
        err.puts stderr unless stderr.empty?
        return false
      end

      verification_errors = verify(
        root,
        bundle,
        opa: opa,
        public_key: key_paths.fetch(:public),
        require_test_key: signing_mode == :test
      )
      unless verification_errors.empty?
        verification_errors.each { |message| err.puts "ERROR: #{message}" }
        return false
      end

      if write
        paths = canonical_paths(root)
        atomic_write(paths.fetch(:bundle), bundle.binread, 0o644)
        if signing_mode == :test
          atomic_write(paths.fetch(:test_public_key), key_paths.fetch(:public).binread, 0o644)
        end
        out.puts "built test-signed bundle: #{paths.fetch(:bundle)}" if signing_mode == :test
        out.puts "built externally signed bundle: #{paths.fetch(:bundle)}" if signing_mode == :external
      else
        out.puts "bundle dry-run passed: #{files.length} logical files, #{bundle.size} bytes"
      end
    end
    true
  rescue ArgumentError, Errno::ENOENT => e
    err.puts "ERROR: #{e.message}"
    false
  end

  def prepare_keys(temp, signing_mode, signing_key, verification_key)
    temp.mkpath if signing_mode == :test
    case signing_mode
    when :test
      key = OpenSSL::PKey::EC.generate("prime256v1")
      private_path = temp.join("TEST-ONLY-private.pem")
      public_path = temp.join("TEST-ONLY-public.pem")
      private_pem = key.respond_to?(:private_to_pem) ? key.private_to_pem : key.to_pem
      public_pem = if key.respond_to?(:public_to_pem)
        key.public_to_pem
      else
        public_key = OpenSSL::PKey::EC.new(key.group)
        public_key.public_key = key.public_key
        public_key.to_pem
      end
      private_path.binwrite(private_pem)
      public_path.binwrite(public_pem)
      File.chmod(0o600, private_path)
      { private: private_path, public: public_path }
    when :external
      private_path = Pathname.new(File.expand_path(signing_key.to_s))
      public_path = Pathname.new(File.expand_path(verification_key.to_s))
      raise ArgumentError, "external signing key is not readable: #{private_path}" unless private_path.file? && private_path.readable?
      raise ArgumentError, "external verification key is not readable: #{public_path}" unless public_path.file? && public_path.readable?
      { private: private_path, public: public_path }
    else
      raise ArgumentError, "signing mode must be test or external"
    end
  end

  def verify(release_root, bundle_path, opa:, public_key:, require_test_key: true, max_bytes: MAX_BUNDLE_BYTES, verify_with_opa: true)
    root = Pathname.new(File.expand_path(release_root))
    bundle = Pathname.new(File.expand_path(bundle_path))
    errors = []
    unless bundle.file?
      return ["bundle is missing: #{bundle}"]
    end
    errors << "bundle exceeds ONIX 10 MiB limit: #{bundle.size} bytes" if bundle.size > max_bytes
    if require_test_key && !Pathname.new(public_key.to_s).basename.to_s.start_with?("TEST-ONLY-")
      errors << "draft bundle verification key must have a TEST-ONLY filename"
    end
    expected, source_errors = expected_files(root)
    errors.concat(source_errors)
    entries, archive_errors = read_archive(bundle)
    errors.concat(archive_errors)

    allowed = expected.keys + [".manifest", ".signatures.json"]
    (expected.keys - entries.keys).each { |name| errors << "bundle is missing source module or data: #{name}" }
    (entries.keys - allowed).each { |name| errors << "bundle contains unexpected file: #{name}" }
    expected.each do |name, content|
      next unless entries.key?(name)
      errors << "bundle content is stale for #{name}" unless entries.fetch(name) == content
    end
    validate_manifest(entries[".manifest"], errors)
    validate_signatures(entries, require_test_key, errors)

    if verify_with_opa && errors.empty?
      errors.concat(verify_signature_with_opa(bundle, opa, public_key))
      errors.concat(validate_public_query(bundle, opa)) if errors.empty?
    end
    errors
  rescue Zlib::GzipFile::Error, Gem::Package::TarInvalidError, JSON::ParserError => e
    ["invalid bundle archive: #{e.message}"]
  end

  def read_archive(bundle)
    entries = {}
    errors = []
    Zlib::GzipReader.open(bundle.to_s) do |gzip|
      Gem::Package::TarReader.new(gzip) do |tar|
        tar.each do |entry|
          raw = entry.full_name
          name = normalize_archive_path(raw)
          unless name
            errors << "bundle contains unsafe archive path: #{raw.inspect}"
            next
          end
          unless entry.file?
            errors << "bundle contains non-file archive entry: #{raw.inspect}"
            next
          end
          if entries.key?(name)
            errors << "bundle contains duplicate archive path: #{name}"
            next
          end
          entries[name] = entry.read
        end
      end
    end
    [entries, errors]
  end

  def normalize_archive_path(raw)
    return nil if raw.include?("\\") || raw.include?("\0")
    name = raw.sub(%r{\A\./}, "").sub(%r{\A/}, "")
    parts = name.split("/")
    return nil if name.empty? || parts.any? { |part| part.empty? || part == "." || part == ".." }
    name
  end

  def validate_manifest(content, errors)
    unless content
      errors << "bundle is missing .manifest"
      return
    end
    manifest = JSON.parse(content)
    errors << "bundle manifest roots must be [\"\"]" unless manifest["roots"] == [""]
    errors << "bundle manifest must declare rego_version 1" unless manifest["rego_version"] == 1
  rescue JSON::ParserError => e
    errors << "bundle .manifest is invalid JSON: #{e.message}"
  end

  def validate_signatures(entries, require_test_key, errors)
    content = entries[".signatures.json"]
    unless content
      errors << "bundle is missing .signatures.json"
      return
    end
    document = JSON.parse(content)
    errors << "bundle signature plugin must be _default" unless document["plugin"] == "_default"
    signatures = document["signatures"]
    unless signatures.is_a?(Array) && signatures.length == 1 && signatures.first.is_a?(String)
      errors << "bundle must contain exactly one embedded signature"
      return
    end
    header, payload = decode_jwt(signatures.first)
    errors << "bundle signature algorithm must be ES256" unless header["alg"] == SIGNING_ALGORITHM
    errors << "bundle signature key ID must be default" unless header["kid"] == SIGNING_KEY_ID && payload["keyid"] == SIGNING_KEY_ID
    signed_files = payload["files"]
    unless signed_files.is_a?(Array)
      errors << "bundle signature payload is missing files"
      return
    end
    signed_names = signed_files.map { |item| item["name"] }
    errors << "bundle signature payload contains duplicate files" if signed_names.uniq.length != signed_names.length
    expected_signed = entries.keys.reject { |name| name == ".signatures.json" }.sort
    errors << "bundle signature inventory does not match archive contents" unless signed_names.sort == expected_signed
    signed_files.each do |item|
      name = item["name"]
      next unless entries.key?(name)
      errors << "bundle signature for #{name} must use SHA-256" unless item["algorithm"] == "SHA-256"
      # OPA canonicalizes parsed data and manifest documents before hashing them.
      # Rego module hashes are over source bytes and can be checked directly here;
      # OPA verification below validates every signed entry cryptographically.
      if name.end_with?(".rego")
        actual = Digest::SHA256.hexdigest(entries.fetch(name))
        errors << "bundle signature hash mismatch for #{name}" unless item["hash"] == actual
      end
    end
  rescue JSON::ParserError, ArgumentError => e
    errors << "bundle signature metadata is invalid: #{e.message}"
  end

  def decode_jwt(token)
    parts = token.split(".")
    raise ArgumentError, "embedded signature is not a three-part JWT" unless parts.length == 3
    [JSON.parse(base64url_decode(parts[0])), JSON.parse(base64url_decode(parts[1]))]
  end

  def base64url_decode(value)
    padding = "=" * ((4 - value.length % 4) % 4)
    Base64.urlsafe_decode64(value + padding)
  end

  def verify_signature_with_opa(bundle, opa, public_key)
    public_path = Pathname.new(File.expand_path(public_key.to_s))
    return ["bundle verification public key is missing: #{public_path}"] unless public_path.file?
    Dir.mktmpdir("ion-rego-verify-") do |temporary|
      output = File.join(temporary, "verified.tar.gz")
      command = [
        opa, "build", "--bundle", bundle.to_s,
        "--verification-key", public_path.to_s,
        "--verification-key-id", SIGNING_KEY_ID,
        "--signing-alg", SIGNING_ALGORITHM,
        "--output", output
      ]
      stdout, stderr, status = Open3.capture3(*command)
      return [] if status.success?
      message = [stdout, stderr].reject(&:empty?).join(" ").strip
      ["OPA bundle signature verification failed: #{message}"]
    end
  rescue Errno::ENOENT => e
    ["OPA bundle signature verification failed: #{e.message}"]
  end

  def validate_public_query(bundle, opa)
    query = "data.ion.release#{release_number_from_bundle_sources(bundle)}.result"
    stdout, stderr, status = Open3.capture3(opa, "eval", "--fail", "--format=json", "--bundle", bundle.to_s, query)
    return ["OPA bundle query evaluation failed: #{stderr.strip}"] unless status.success?
    response = JSON.parse(stdout)
    value = response.fetch("result").fetch(0).fetch("expressions").fetch(0).fetch("value")
    unless value.is_a?(Hash) && [true, false].include?(value["valid"]) && value["violations"].is_a?(Array)
      return ["OPA bundle query #{query} returned an invalid result contract"]
    end
    []
  rescue JSON::ParserError, KeyError, IndexError, NoMethodError => e
    ["OPA bundle query returned invalid output: #{e.message}"]
  end

  def release_number_from_bundle_sources(bundle)
    entries, = read_archive(bundle)
    module_name = entries.keys.find { |name| name.match?(%r{\Aion/release\d+/.+\.rego\z}) }
    raise ArgumentError, "bundle has no release-qualified module" unless module_name
    module_name[%r{\Aion/release(\d+)/}, 1].to_i
  end

  def release_number(root)
    manifest = YAML.safe_load(root.join("release.yaml").read, aliases: true)
    Integer(manifest.fetch("release"))
  end

  def symlink_in_path?(root, path)
    relative = Pathname.new(path).relative_path_from(Pathname.new(root))
    current = Pathname.new(root)
    relative.each_filename.any? do |part|
      current = current.join(part)
      current.symlink?
    end
  rescue ArgumentError
    true
  end

  def atomic_write(path, content, mode)
    path.dirname.mkpath
    temporary = Tempfile.new([path.basename.to_s, ".tmp"], path.dirname.to_s)
    temporary.binmode
    temporary.write(content)
    temporary.flush
    temporary.fsync
    temporary.chmod(mode)
    temporary.close
    File.rename(temporary.path, path.to_s)
  ensure
    if temporary
      temporary.close unless temporary.closed?
      File.unlink(temporary.path) if File.exist?(temporary.path)
    end
  end
end
