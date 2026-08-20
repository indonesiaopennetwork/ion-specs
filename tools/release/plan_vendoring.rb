#!/usr/bin/env ruby

require "date"
require "digest"
require "json"
require "net/http"
require "optparse"
require "time"
require "uri"
require "yaml"

module IonVendoringPlan
  REGISTRY_HOST = "schema.beckn.io".freeze
  PUBLIC_RELEASE_BASE = "https://schema.ion.id/releases/release1/".freeze

  SOURCE_RULES = [
    {
      "pattern" => /\ARetail/,
      "repository" => "https://github.com/beckn/local-retail",
      "apiRepository" => "beckn/local-retail",
      "branch" => "main",
      "licensePath" => "LICENSE.md"
    },
    {
      "pattern" => /.*/,
      "repository" => "https://github.com/beckn/schemas",
      "apiRepository" => "beckn/schemas",
      "branch" => "main",
      "licensePath" => "LICENSE.md"
    }
  ].freeze

  module_function

  def collect_refs(value, result = [])
    case value
    when Hash
      value.each do |key, child|
        result << child if key == "$ref" && child.is_a?(String)
        collect_refs(child, result)
      end
    when Array
      value.each { |child| collect_refs(child, result) }
    end
    result
  end

  def registry_reference(ref)
    uri = URI.parse(ref)
    return nil unless uri.scheme == "https" && uri.host == REGISTRY_HOST

    segments = uri.path.split("/").reject(&:empty?)
    return nil unless segments.length.between?(2, 3)
    return nil if segments.length == 3 && segments[2] != "attributes.yaml"

    family = segments[0]
    requested_version = segments[1]
    return nil unless requested_version.match?(/\Av?\d+\.\d+(?:\.\d+)?\z/)

    version = requested_version.delete_prefix("v")
    {
      "family" => family,
      "version" => version,
      "requestedVersionSegment" => requested_version,
      "documentUrl" => ref.split("#", 2).first,
      "fragment" => ref.split("#", 2)[1],
      "key" => "#{family}@#{version}"
    }
  rescue URI::InvalidURIError
    nil
  end

  def source_rule(family)
    SOURCE_RULES.find { |rule| rule.fetch("pattern").match?(family) }
  end

  def upstream_path(family, version)
    "schema/#{family}/v#{version}/attributes.yaml"
  end

  def target_path(family, version)
    "releases/release1/vendored/beckn/schemas/#{family}/#{version}/attributes.yaml"
  end

  def strip_vendoring_header(content)
    start = content.index(/^openapi:/)
    start ? content[start..] : content
  end

  def line_difference_summary(upstream, candidate, limit: 20)
    upstream_lines = upstream.to_s.lines
    candidate_lines = candidate.to_s.lines
    differences = []
    [upstream_lines.length, candidate_lines.length].max.times do |index|
      next if upstream_lines[index] == candidate_lines[index]
      differences << {
        "line" => index + 1,
        "upstream" => upstream_lines[index]&.chomp,
        "candidate" => candidate_lines[index]&.chomp
      }
    end
    {
      "upstreamLineCount" => upstream_lines.length,
      "candidateLineCount" => candidate_lines.length,
      "differenceCount" => differences.length,
      "differences" => differences.first(limit),
      "truncated" => differences.length > limit
    }
  end

  def parse_document(body, url)
    YAML.safe_load(body, permitted_classes: [Date, Time], aliases: true)
  rescue Psych::SyntaxError => e
    raise ArgumentError, "invalid YAML from #{url}: #{e.message}"
  end

  def document_metadata(document)
    info = document.is_a?(Hash) && document["info"].is_a?(Hash) ? document["info"] : {}
    {
      "title" => info["title"],
      "declaredVersion" => info["version"],
      "declaredLicense" => info["license"]
    }
  end

  class HttpFetcher
    def initialize(user_agent: "ion-specs-vendoring-plan/1")
      @user_agent = user_agent
    end

    def fetch(url, redirects: 5)
      raise ArgumentError, "too many redirects for #{url}" if redirects.negative?

      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = @user_agent
      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 15,
        read_timeout: 30
      ) { |http| http.request(request) }

      case response
      when Net::HTTPSuccess
        body = response.body.dup.force_encoding(Encoding::UTF_8)
        raise ArgumentError, "response is not valid UTF-8 for #{url}" unless body.valid_encoding?
        body
      when Net::HTTPRedirection
        location = URI.join(url, response.fetch("location")).to_s
        fetch(location, redirects: redirects - 1)
      else
        raise ArgumentError, "HTTP #{response.code} for #{url}"
      end
    rescue SocketError, SystemCallError, Timeout::Error => e
      raise ArgumentError, "network error for #{url}: #{e.message}"
    end
  end

  class Planner
    def initialize(release_root:, fetcher: HttpFetcher.new, protocol_selection: "historical")
      @release_root = File.expand_path(release_root)
      @repository_root = File.expand_path("../..", @release_root)
      @fetcher = fetcher
      @protocol_selection = protocol_selection
      unless %w[historical latest].include?(@protocol_selection)
        raise ArgumentError, "protocol selection must be historical or latest"
      end
      @repository_heads = {}
      @repository_licenses = {}
      @issues = []
    end

    def build
      direct = direct_registry_references
      documents, dependencies = discover_dependencies(direct)
      dependency_records = dependencies.keys.sort.map do |key|
        build_dependency_record(key, dependencies.fetch(key), documents)
      end
      protocol = build_protocol_record

      {
        "schemaVersion" => 1,
        "release" => 1,
        "status" => "proposed",
        "generatedAt" => Time.now.utc.iso8601,
        "scope" => {
          "releaseRoot" => relative_to_repository(@release_root),
          "rule" => "Versions are derived from existing Release 1 $ref values; transitive versions are derived from the fetched upstream documents.",
          "noReleaseFilesWritten" => true
        },
        "protocol" => protocol,
        "dependencies" => dependency_records,
        "repositories" => repository_records,
        "summary" => {
          "directReferenceOccurrences" => direct.values.sum { |entry| entry.fetch("occurrences") },
          "directDocumentUrls" => direct.length,
          "resolvedFamilyVersions" => dependency_records.length,
          "transitiveFamilyVersions" => dependency_records.count { |entry| !entry.fetch("direct") },
          "verifiedFamilyVersions" => dependency_records.count { |entry| entry["provenanceStatus"] == "verified" },
          "blockingIssueCount" => @issues.length
        },
        "blockingIssues" => @issues.sort_by { |issue| [issue["dependency"].to_s, issue["code"], issue["message"]] }
      }
    end

    private

    def direct_registry_references
      refs = {}
      Dir.glob(File.join(@release_root, "**/*.{yaml,yml,json}")).sort.each do |file|
        document = load_local_document(file)
        IonVendoringPlan.collect_refs(document).each do |ref|
          parsed = IonVendoringPlan.registry_reference(ref)
          next unless parsed

          entry = refs[parsed.fetch("documentUrl")] ||= {
            "parsed" => parsed,
            "occurrences" => 0,
            "requestedBy" => []
          }
          entry["occurrences"] += 1
          entry["requestedBy"] << relative_to_release(file)
          entry["requestedBy"].uniq!
          entry["requestedBy"].sort!
        end
      end
      refs
    end

    def discover_dependencies(direct)
      documents = {}
      dependencies = {}
      queue = direct.keys.sort.map do |url|
        [url, direct.fetch(url).fetch("requestedBy"), true]
      end

      until queue.empty?
        url, requesters, direct_dependency = queue.shift
        parsed = IonVendoringPlan.registry_reference(url)
        unless parsed
          add_issue("unsupported-registry-url", url, "Cannot derive a family and version from #{url}")
          next
        end

        dependency = dependencies[parsed.fetch("key")] ||= {
          "family" => parsed.fetch("family"),
          "version" => parsed.fetch("version"),
          "direct" => false,
          "requestedBy" => [],
          "registryUrls" => []
        }
        dependency["direct"] ||= direct_dependency
        dependency["requestedBy"].concat(requesters).uniq!
        dependency["requestedBy"].sort!
        dependency["registryUrls"] << url unless dependency["registryUrls"].include?(url)
        next if documents.key?(url)

        begin
          body = @fetcher.fetch(url)
          document = IonVendoringPlan.parse_document(body, url)
          documents[url] = {
            "sha256" => Digest::SHA256.hexdigest(body),
            "metadata" => IonVendoringPlan.document_metadata(document),
            "body" => body
          }
          IonVendoringPlan.collect_refs(document).each do |ref|
            transitive = IonVendoringPlan.registry_reference(ref)
            next unless transitive

            queue << [transitive.fetch("documentUrl"), [parsed.fetch("key")], false]
          end
        rescue ArgumentError => e
          add_issue("registry-fetch-failed", parsed.fetch("key"), e.message)
        end
      end

      [documents, dependencies]
    end

    def build_dependency_record(key, dependency, documents)
      family = dependency.fetch("family")
      version = dependency.fetch("version")
      rule = IonVendoringPlan.source_rule(family)
      repo = rule.fetch("apiRepository")
      commit = repository_head(repo, rule.fetch("branch"))
      path = IonVendoringPlan.upstream_path(family, version)
      upstream_url = "https://raw.githubusercontent.com/#{repo}/#{commit}/#{path}"
      registry_documents = dependency.fetch("registryUrls").sort.map do |url|
        data = documents[url]
        {
          "url" => url,
          "sha256" => data && data["sha256"],
          "title" => data && data.fetch("metadata")["title"],
          "declaredVersion" => data && data.fetch("metadata")["declaredVersion"],
          "declaredLicense" => data && data.fetch("metadata")["declaredLicense"]
        }
      end

      upstream_sha = nil
      begin
        upstream_body = @fetcher.fetch(upstream_url)
        upstream_sha = Digest::SHA256.hexdigest(upstream_body)
      rescue ArgumentError => e
        add_issue("upstream-fetch-failed", key, e.message)
      end

      registry_shas = registry_documents.map { |entry| entry["sha256"] }.compact.uniq
      if registry_shas.length > 1
        add_issue("registry-alias-mismatch", key, "Registry URL aliases return different content checksums")
      end
      if upstream_sha && (!registry_shas.empty? && registry_shas != [upstream_sha])
        add_issue("registry-upstream-mismatch", key, "Registry content does not match the proposed immutable upstream file")
      end

      verified = upstream_sha && registry_shas == [upstream_sha]
      declared_licenses = registry_documents.map { |entry| entry["declaredLicense"] }.compact.uniq
      repository_license = repository_license(
        repo,
        rule.fetch("repository"),
        commit,
        rule.fetch("licensePath")
      )
      {
        "name" => family,
        "version" => version,
        "direct" => dependency.fetch("direct"),
        "requestedBy" => dependency.fetch("requestedBy"),
        "registryDocuments" => registry_documents,
        "upstream" => {
          "repository" => rule.fetch("repository"),
          "branchAtPlanning" => rule.fetch("branch"),
          "commit" => commit,
          "path" => path,
          "rawUrl" => upstream_url,
          "sha256" => upstream_sha
        },
        "provenanceStatus" => verified ? "verified" : "blocked",
        "license" => {
          "declaredInDocument" => declared_licenses,
          "repositoryLicense" => repository_license,
          "reviewStatus" => "proposed"
        },
        "target" => IonVendoringPlan.target_path(family, version),
        "publicUrl" => "#{PUBLIC_RELEASE_BASE}vendored/beckn/schemas/#{family}/#{version}/attributes.yaml"
      }
    end

    def build_protocol_record
      repo = "beckn/protocol-specifications-v2"
      branch = "main"
      path = "api/v2.0.0/beckn.yaml"
      sync_date = protocol_sync_date
      historical_commit = repository_file_commit(repo, branch, path, sync_date)
      current_head = repository_head(repo, branch)
      commit = @protocol_selection == "latest" ? current_head : historical_commit
      raw_url = "https://raw.githubusercontent.com/#{repo}/#{commit}/#{path}"
      local_path = File.join(@release_root, "vendored/beckn/protocol/v2.0.0/beckn.yaml")
      local_body = File.file?(local_path) ? File.read(local_path) : nil
      local_sha = local_body && Digest::SHA256.hexdigest(local_body)
      candidate_payload = local_body && IonVendoringPlan.strip_vendoring_header(local_body)
      candidate_payload_sha = candidate_payload && Digest::SHA256.hexdigest(candidate_payload)
      upstream_sha = nil
      upstream_body = nil
      begin
        upstream_body = @fetcher.fetch(raw_url)
        upstream_sha = Digest::SHA256.hexdigest(upstream_body)
      rescue ArgumentError => e
        add_issue("protocol-upstream-fetch-failed", "BecknProtocol@2.0.0", e.message)
      end
      matches = candidate_payload_sha && upstream_sha && candidate_payload_sha == upstream_sha
      add_issue(
        "protocol-candidate-content-mismatch",
        "BecknProtocol@2.0.0",
        "The existing Release 1 candidate payload does not exactly match the proposed historical upstream file; review the local modification before approval"
      ) if @protocol_selection == "historical" && !matches

      alternative_commit = @protocol_selection == "latest" ? historical_commit : current_head
      alternative_url = "https://raw.githubusercontent.com/#{repo}/#{alternative_commit}/#{path}"
      alternative_sha = Digest::SHA256.hexdigest(@fetcher.fetch(alternative_url))
      license = repository_license(
        repo,
        "https://github.com/#{repo}",
        commit,
        "LICENSE"
      )

      {
        "name" => "BecknProtocol",
        "version" => "2.0.0",
        "existingCandidate" => relative_to_repository(local_path),
        "candidateSha256" => local_sha,
        "candidatePayloadSha256" => candidate_payload_sha,
        "vendoringHeaderPresent" => !!(local_body && local_body.start_with?("# =============================================================================\n# VENDORED DEPENDENCY")),
        "upstream" => {
          "repository" => "https://github.com/#{repo}",
          "selectionMode" => @protocol_selection,
          "selectionBasis" => if @protocol_selection == "latest"
                                "Current main HEAD at plan generation, explicitly selected for Release 1"
                              else
                                "Latest commit touching #{path} on or before #{sync_date}, derived from becknCoreUpstreamTag"
                              end,
          "declaredSyncDate" => sync_date,
          "commit" => commit,
          "path" => path,
          "rawUrl" => raw_url,
          "sha256" => upstream_sha
        },
        "candidatePayloadMatchesUpstream" => !!matches,
        "candidatePayloadDifference" => IonVendoringPlan.line_difference_summary(
          upstream_body,
          candidate_payload
        ),
        "alternative" => {
          "selectionMode" => @protocol_selection == "latest" ? "historical" : "latest",
          "commit" => alternative_commit,
          "rawUrl" => alternative_url,
          "sha256" => alternative_sha,
          "selected" => false,
          "reason" => @protocol_selection == "latest" ?
            "Historical snapshot associated with the prior declared sync date" :
            "Current main differs from the historically synchronized candidate and would be an explicit dependency upgrade"
        },
        "license" => license.merge("reviewStatus" => "proposed"),
        "action" => matches ? "retain" : "replace-with-upstream",
        "provenanceStatus" => upstream_sha ? "verified" : "blocked"
      }
    end

    def protocol_sync_date
      ion_path = File.join(@release_root, "core/api/v2.0.0/ion.yaml")
      content = File.read(ion_path)
      match = content.match(/becknCoreUpstreamTag:\s*main-(\d{4}-\d{2}-\d{2})/)
      raise ArgumentError, "cannot derive protocol sync date from becknCoreUpstreamTag" unless match
      match[1]
    end

    def repository_file_commit(repo, branch, path, through_date)
      query = URI.encode_www_form(
        "sha" => branch,
        "path" => path,
        "until" => "#{through_date}T23:59:59Z",
        "per_page" => 1
      )
      url = "https://api.github.com/repos/#{repo}/commits?#{query}"
      data = JSON.parse(@fetcher.fetch(url))
      sha = data.is_a?(Array) && data[0].is_a?(Hash) ? data[0]["sha"] : nil
      unless sha.is_a?(String) && sha.match?(/\A[0-9a-f]{40}\z/)
        raise ArgumentError, "GitHub did not return a file commit for #{repo}/#{path} through #{through_date}"
      end
      sha
    rescue JSON::ParserError => e
      raise ArgumentError, "invalid GitHub file-history response for #{repo}/#{path}: #{e.message}"
    end

    def repository_head(repo, branch)
      key = "#{repo}@#{branch}"
      @repository_heads[key] ||= begin
        url = "https://api.github.com/repos/#{repo}/commits/#{branch}"
        data = JSON.parse(@fetcher.fetch(url))
        sha = data["sha"]
        raise ArgumentError, "GitHub response did not contain a commit SHA for #{key}" unless sha.is_a?(String) && sha.match?(/\A[0-9a-f]{40}\z/)
        sha
      rescue JSON::ParserError => e
        raise ArgumentError, "invalid GitHub response for #{key}: #{e.message}"
      end
    end

    def repository_records
      @repository_licenses.keys.sort.map { |key| @repository_licenses.fetch(key) }
    end

    def repository_license(repo, repository_url, commit, path)
      key = "#{repo}@#{commit}:#{path}"
      @repository_licenses[key] ||= begin
        raw_url = "https://raw.githubusercontent.com/#{repo}/#{commit}/#{path}"
        body = @fetcher.fetch(raw_url)
        {
          "repository" => repository_url,
          "commit" => commit,
          "path" => path,
          "rawUrl" => raw_url,
          "sha256" => Digest::SHA256.hexdigest(body)
        }
      rescue ArgumentError => e
        add_issue("license-fetch-failed", key, e.message)
        {
          "repository" => repository_url,
          "commit" => commit,
          "path" => path,
          "rawUrl" => raw_url,
          "sha256" => nil
        }
      end
    end

    def load_local_document(path)
      if [".json", ".jsonld"].include?(File.extname(path))
        JSON.parse(File.read(path))
      else
        YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
      end
    end

    def relative_to_release(path)
      File.expand_path(path).delete_prefix("#{@release_root}/")
    end

    def relative_to_repository(path)
      File.expand_path(path).delete_prefix("#{@repository_root}/")
    end

    def add_issue(code, dependency, message)
      issue = { "code" => code, "dependency" => dependency, "message" => message }
      @issues << issue unless @issues.include?(issue)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    release_root: "releases/release1",
    output: "tools/release/release1-vendoring-plan.json",
    protocol_selection: "historical"
  }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/release/plan_vendoring.rb [options]"
    opts.on("--release-root PATH", "Draft release root") { |value| options[:release_root] = value }
    opts.on("--output PATH", "Proposed plan output path") { |value| options[:output] = value }
    opts.on("--protocol-selection MODE", "historical or latest") { |value| options[:protocol_selection] = value }
  end
  parser.parse!

  release_root = File.expand_path(options.fetch(:release_root))
  output = File.expand_path(options.fetch(:output))
  unless File.directory?(release_root)
    warn "ERROR: release root does not exist: #{options.fetch(:release_root)}"
    exit 1
  end
  if output == release_root || output.start_with?("#{release_root}/")
    warn "ERROR: proposed plans must not be written inside the release directory"
    exit 1
  end

  begin
    plan = IonVendoringPlan::Planner.new(
      release_root: release_root,
      protocol_selection: options.fetch(:protocol_selection)
    ).build
    File.write(output, "#{JSON.pretty_generate(plan)}\n")
  rescue ArgumentError, JSON::ParserError, Psych::SyntaxError => e
    warn "ERROR: #{e.message}"
    exit 1
  end

  puts "wrote proposed vendoring plan: #{options.fetch(:output)}"
  puts "dependencies: #{plan.fetch("dependencies").length}"
  puts "blocking issues: #{plan.fetch("blockingIssues").length}"
end
