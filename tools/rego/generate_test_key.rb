#!/usr/bin/env ruby

require "fileutils"
require "openssl"
require "optparse"
require "pathname"

module IonRegoTestKey
  PRIVATE_NAME = "TEST-ONLY-opa-es256-private.pem"
  PUBLIC_NAME = "TEST-ONLY-opa-es256-public.pem"

  module_function

  def generate(output_directory, repository_root:, write: false, out: $stdout)
    output = Pathname.new(File.expand_path(output_directory))
    release_root = Pathname.new(repository_root).join("releases").expand_path
    if output == release_root || output.to_s.start_with?("#{release_root}#{File::SEPARATOR}")
      raise ArgumentError, "test keys must not be written inside releases/"
    end

    private_path = output.join(PRIVATE_NAME)
    public_path = output.join(PUBLIC_NAME)
    if !write
      out.puts "dry-run: generate non-production ES256 test key"
      out.puts "private: #{private_path}"
      out.puts "public:  #{public_path}"
      return { private: private_path, public: public_path, mode: "dry-run" }
    end

    [private_path, public_path].each do |path|
      raise ArgumentError, "refusing to overwrite test key: #{path}" if path.exist?
    end

    FileUtils.mkdir_p(output)
    key = OpenSSL::PKey::EC.generate("prime256v1")
    private_pem = key.respond_to?(:private_to_pem) ? key.private_to_pem : key.to_pem
    public_pem = if key.respond_to?(:public_to_pem)
      key.public_to_pem
    else
      public_key = OpenSSL::PKey::EC.new(key.group)
      public_key.public_key = key.public_key
      public_key.to_pem
    end
    private_path.open("w", 0o600) { |file| file.write(private_pem) }
    public_path.open("w", 0o644) { |file| file.write(public_pem) }
    out.puts "generated TEST-ONLY ES256 keypair: #{output}"
    { private: private_path, public: public_path, mode: "write" }
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    write: false,
    repository_root: File.expand_path("../..", __dir__)
  }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/rego/generate_test_key.rb [--write] OUTPUT_DIRECTORY"
    opts.on("--write", "Generate the test-only keypair; default is dry-run") { options[:write] = true }
  end

  begin
    parser.parse!
    output_directory = ARGV.fetch(0)
    IonRegoTestKey.generate(output_directory, **options)
  rescue IndexError, OptionParser::ParseError, ArgumentError => e
    warn e.message
    warn parser
    exit 1
  end
end
