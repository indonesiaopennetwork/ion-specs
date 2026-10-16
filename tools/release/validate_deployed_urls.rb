#!/usr/bin/env ruby

require "digest"
require "net/http"
require "optparse"
require "pathname"
require "thread"
require "uri"
require "yaml"

module IonDeployedUrls
  Result = Struct.new(:status, :content_type, :body, :error, keyword_init: true)

  CONTENT_TYPES = {
    ".json" => "application/json",
    ".jsonld" => "application/ld+json",
    ".md" => "text/markdown",
    ".yaml" => "application/yaml",
    ".yml" => "application/yaml"
  }.freeze

  module_function

  def validate(release_root, base_url: nil, jobs: 8, attempts: 3, retry_delay: 5, fetcher: method(:fetch), sleeper: Kernel)
    root = Pathname.new(File.expand_path(release_root))
    manifest = YAML.safe_load(root.join("release.yaml").read, aliases: true)
    base_url ||= manifest.fetch("publicBaseUrl")
    base_url = "#{base_url}/" unless base_url.end_with?("/")
    artifacts = deployed_artifacts(root)
    pending = artifacts
    failures = {}

    attempts.times do |attempt|
      failures = fetch_all(pending, base_url, jobs, fetcher)
      break if failures.empty? || attempt == attempts - 1

      warn "deployment audit attempt #{attempt + 1}/#{attempts}: #{failures.length} artifact(s) not ready; retrying in #{retry_delay}s"
      sleeper.sleep(retry_delay)
      pending = artifacts.select { |artifact| failures.key?(artifact.fetch(:path)) }
    end

    [artifacts.length, failures.values]
  rescue Errno::ENOENT, Psych::SyntaxError, KeyError, URI::InvalidURIError => e
    [0, [e.message.lines.first.strip]]
  end

  def deployed_artifacts(root)
    paths = Dir.glob(root.join("**/*").to_s, File::FNM_DOTMATCH).sort
    paths.each_with_object([]) do |path_string, artifacts|
      path = Pathname.new(path_string)
      next unless path.file?

      relative = path.relative_path_from(root).to_s
      next if relative.split("/").any? { |segment| segment.start_with?(".") }

      artifacts << {
        path: relative,
        sha256: Digest::SHA256.file(path).hexdigest,
        content_type: expected_content_type(relative)
      }
    end
  end

  def expected_content_type(path)
    CONTENT_TYPES.fetch(File.extname(path), "application/octet-stream")
  end

  def fetch_all(artifacts, base_url, jobs, fetcher)
    queue = Queue.new
    artifacts.each { |artifact| queue << artifact }
    failures = {}
    mutex = Mutex.new
    worker_count = [[jobs, 1].max, [artifacts.length, 1].max].min

    workers = worker_count.times.map do
      Thread.new do
        loop do
          artifact = queue.pop(true)
          url = public_url(base_url, artifact.fetch(:path))
          result = fetcher.call(url)
          failure = failure_for(artifact, result, url)
          mutex.synchronize { failures[artifact.fetch(:path)] = failure } if failure
        rescue ThreadError
          break
        rescue StandardError => e
          mutex.synchronize { failures[artifact.fetch(:path)] = "#{artifact.fetch(:path)}: #{e.class}: #{e.message}" }
        end
      end
    end
    workers.each(&:join)
    failures
  end

  def public_url(base_url, path)
    escaped = path.split("/").map { |segment| URI.encode_www_form_component(segment).gsub("+", "%20") }.join("/")
    URI.join(base_url, escaped).to_s
  end

  def failure_for(artifact, result, url)
    return "#{artifact.fetch(:path)}: request failed for #{url}: #{result.error}" if result.error
    return "#{artifact.fetch(:path)}: expected HTTP 200, got #{result.status}" unless result.status == 200

    actual_type = result.content_type.to_s.split(";", 2).first.downcase
    expected_type = artifact.fetch(:content_type)
    return "#{artifact.fetch(:path)}: expected Content-Type #{expected_type}, got #{result.content_type.inspect}" unless actual_type == expected_type

    actual_sha = Digest::SHA256.hexdigest(result.body.to_s)
    return "#{artifact.fetch(:path)}: deployed SHA-256 #{actual_sha} does not match local #{artifact.fetch(:sha256)}" unless actual_sha == artifact.fetch(:sha256)

    nil
  end

  def fetch(url, redirects = 3)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["Accept-Encoding"] = "identity"
    request["Cache-Control"] = "no-cache"
    request["User-Agent"] = "ion-release-deployment-validator/1"
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 30
    ) { |http| http.request(request) }

    if response.is_a?(Net::HTTPRedirection)
      return Result.new(error: "too many redirects") if redirects.zero?
      location = response["location"]
      return Result.new(error: "redirect has no Location header") unless location

      return fetch(URI.join(url, location).to_s, redirects - 1)
    end

    Result.new(
      status: response.code.to_i,
      content_type: response["content-type"],
      body: response.body.to_s.b
    )
  rescue StandardError => e
    Result.new(error: "#{e.class}: #{e.message}")
  end
end

if $PROGRAM_NAME == __FILE__
  options = { jobs: 8, attempts: 3, retry_delay: 5 }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/release/validate_deployed_urls.rb [options] RELEASE_ROOT"
    opts.on("--base-url URL", "Override manifest publicBaseUrl for a preview deployment") { |value| options[:base_url] = value }
    opts.on("--jobs N", Integer, "Concurrent requests (default: 8)") { |value| options[:jobs] = value }
    opts.on("--attempts N", Integer, "Complete or failed-subset attempts (default: 3)") { |value| options[:attempts] = value }
    opts.on("--retry-delay SECONDS", Integer, "Delay between attempts (default: 5)") { |value| options[:retry_delay] = value }
  end

  begin
    parser.parse!
    release_root = ARGV.fetch(0)
    raise OptionParser::InvalidArgument, "--jobs must be positive" unless options[:jobs].positive?
    raise OptionParser::InvalidArgument, "--attempts must be positive" unless options[:attempts].positive?
    raise OptionParser::InvalidArgument, "--retry-delay must not be negative" if options[:retry_delay].negative?
  rescue IndexError, OptionParser::ParseError => e
    warn e.message
    warn parser
    exit 2
  end

  count, failures = IonDeployedUrls.validate(release_root, **options)
  if failures.empty?
    deployed_base = options[:base_url] || YAML.load_file(File.join(release_root, "release.yaml")).fetch("publicBaseUrl")
    puts "deployed release validation passed: #{count} artifacts at #{deployed_base}"
  else
    warn "deployed release validation failed with #{failures.length} error(s):"
    failures.each { |failure| warn "- #{failure}" }
    exit 1
  end
end
