#!/usr/bin/env ruby

require "date"
require "digest"
require "fileutils"
require "json"
require "optparse"
require "pathname"
require "yaml"

require_relative "plan_vendoring"

module IonVendoringApply
  PROTOCOL_PUBLIC_URL = "https://schema.ion.id/release1/schema/vendored/beckn/protocol/v2.0.0/beckn.yaml".freeze
  LICENSE_TARGETS = {
    "https://github.com/beckn/protocol-specifications-v2" => "releases/release1/schema/vendored/beckn/licenses/protocol-specifications-v2/LICENSE",
    "https://github.com/beckn/schemas" => "releases/release1/schema/vendored/beckn/licenses/schemas/LICENSE.md",
    "https://github.com/beckn/local-retail" => "releases/release1/schema/vendored/beckn/licenses/local-retail/LICENSE.md"
  }.freeze
  ION_INTERNAL_REFS = {
    "#/components/schemas/Attributes" => "#{PROTOCOL_PUBLIC_URL}#/components/schemas/Attributes",
    "#/components/schemas/GeoJSONGeometry" => "#{PROTOCOL_PUBLIC_URL}#/components/schemas/GeoJSONGeometry",
    "#/components/schemas/Document" => "#{PROTOCOL_PUBLIC_URL}#/components/schemas/Document"
  }.freeze

  module_function

  def sha256(body)
    Digest::SHA256.hexdigest(body)
  end

  def parse_document(body, label)
    YAML.safe_load(body, permitted_classes: [Date, Time], aliases: true)
  rescue Psych::SyntaxError => e
    raise ArgumentError, "invalid YAML/JSON in #{label}: #{e.message}"
  end

  def ref_aliases(dependencies)
    dependencies.each_with_object({}) do |dependency, aliases|
      family = dependency.fetch("name")
      version = dependency.fetch("version")
      public_url = dependency.fetch("publicUrl")
      version_segments = [version, "v#{version}"]
      version_segments.each do |segment|
        aliases["https://schema.beckn.io/#{family}/#{segment}"] = public_url
        aliases["https://schema.beckn.io/#{family}/#{segment}/attributes.yaml"] = public_url
      end
      dependency.fetch("registryDocuments").each do |document|
        aliases[document.fetch("url")] = public_url
      end
    end
  end

  def rewrite_ref_lines(body, aliases, extra_refs: {})
    replacements = aliases.sort_by { |source, _| -source.length }
    count = 0
    rewritten = body.lines.map do |line|
      next line unless line.include?("$ref")

      extra_refs.each do |source, target|
        next unless ref_value(line) == source

        line = line.sub(source, target)
        count += 1
      end
      replacements.each do |source, target|
        occurrences = line.scan(source).length
        next if occurrences.zero?

        line = line.gsub(source, target)
        count += occurrences
      end
      line
    end.join
    [rewritten, count]
  end

  def ref_value(line)
    match = line.match(/["']?\$ref["']?\s*:\s*["']?([^"'\s,}]+)["']?\s*[,}]?\s*\z/)
    match && match[1]
  end

  class Applier
    attr_reader :summary

    def initialize(repository_root:, plan_path:, apply:, fetcher: IonVendoringPlan::HttpFetcher.new)
      @repository_root = File.expand_path(repository_root)
      @plan_path = File.expand_path(plan_path, @repository_root)
      @apply = apply
      @fetcher = fetcher
      @summary = {}
    end

    def run
      plan = JSON.parse(File.read(@plan_path))
      release_root = contained_path(plan.dig("scope", "releaseRoot"))
      manifest_path = File.join(release_root, "release.yaml")
      manifest = IonVendoringApply.parse_document(File.read(manifest_path), manifest_path)
      validate_gates!(plan, manifest)

      aliases = IonVendoringApply.ref_aliases(plan.fetch("dependencies"))
      staged = fetch_pinned_files(plan)
      release_documents(release_root).each do |path|
        staged[path] ||= File.binread(path)
      end

      rewrite_count = 0
      staged.keys.grep(/\.(?:yaml|yml|json)\z/).each do |path|
        extra_refs = path == File.join(release_root, "schema/core/api/v2.0.0/ion.yaml") ? ION_INTERNAL_REFS : {}
        rewritten, count = IonVendoringApply.rewrite_ref_lines(staged.fetch(path), aliases, extra_refs: extra_refs)
        IonVendoringApply.parse_document(rewritten, path)
        staged[path] = rewritten
        rewrite_count += count
      end

      ensure_no_external_refs!(staged)
      changed = staged.select { |path, body| !File.exist?(path) || File.binread(path) != body.b }
      write_files(changed) if @apply

      @summary = {
        "mode" => @apply ? "apply" : "dry-run",
        "fetchedDependencies" => plan.fetch("dependencies").length + 1,
        "fetchedLicenses" => plan.fetch("repositories").length,
        "referenceRewrites" => rewrite_count,
        "changedFiles" => changed.keys.map { |path| relative(path) }.sort
      }
    end

    private

    def validate_gates!(plan, manifest)
      raise ArgumentError, "release manifest must remain draft during migration" unless manifest["status"] == "draft"
      raise ArgumentError, "vendoring plan is not approved" unless plan["status"] == "approved"
      raise ArgumentError, "vendoring plan has blocking issues" unless plan.fetch("blockingIssues").empty?
      raise ArgumentError, "vendoring plan has no recorded approval" unless plan["approval"].is_a?(Hash)
      unless plan.fetch("dependencies").all? { |dependency| dependency["provenanceStatus"] == "verified" }
        raise ArgumentError, "not all schema dependencies have verified provenance"
      end
      unless plan.dig("protocol", "provenanceStatus") == "verified"
        raise ArgumentError, "protocol provenance is not verified"
      end
    end

    def fetch_pinned_files(plan)
      staged = {}
      protocol = plan.fetch("protocol")
      upstream = protocol.fetch("upstream")
      stage_fetch(staged, contained_path(protocol.fetch("existingCandidate")), upstream)

      plan.fetch("dependencies").each do |dependency|
        stage_fetch(staged, contained_path(dependency.fetch("target")), dependency.fetch("upstream"))
      end

      plan.fetch("repositories").each do |license|
        target = LICENSE_TARGETS.fetch(license.fetch("repository"))
        stage_fetch(staged, contained_path(target), license)
      end
      staged
    end

    def stage_fetch(staged, target, source)
      body = @fetcher.fetch(source.fetch("rawUrl"))
      actual = IonVendoringApply.sha256(body)
      expected = source.fetch("sha256")
      raise ArgumentError, "checksum mismatch for #{source.fetch("rawUrl")}: expected #{expected}, got #{actual}" unless actual == expected

      staged[target] = body
    end

    def release_documents(release_root)
      Dir.glob(File.join(release_root, "**/*.{yaml,yml,json}")).sort
    end

    def ensure_no_external_refs!(staged)
      unresolved = []
      staged.each do |path, body|
        next unless path.match?(/\.(?:yaml|yml|json)\z/)

        document = IonVendoringApply.parse_document(body, path)
        IonVendoringPlan.collect_refs(document).each do |ref|
          unresolved << "#{relative(path)}: #{ref}" if ref.include?("schema.beckn.io")
        end
      end
      return if unresolved.empty?

      raise ArgumentError, "unresolved schema.beckn.io $ref values:\n#{unresolved.join("\n")}"
    end

    def write_files(files)
      files.sort.each do |path, body|
        FileUtils.mkdir_p(File.dirname(path))
        File.binwrite(path, body)
      end
    end

    def contained_path(relative_path)
      path = File.expand_path(relative_path, @repository_root)
      root_prefix = @repository_root.end_with?(File::SEPARATOR) ? @repository_root : "#{@repository_root}#{File::SEPARATOR}"
      raise ArgumentError, "path escapes repository: #{relative_path}" unless path.start_with?(root_prefix)

      path
    end

    def relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(@repository_root)).to_s
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    options = {
      apply: false,
      plan: "tools/release/release1-vendoring-plan.json"
    }
    OptionParser.new do |parser|
      parser.banner = "Usage: ruby tools/release/apply_vendoring_plan.rb [--apply]"
      parser.on("--apply", "Write the checksum-verified approved plan (default: dry-run)") { options[:apply] = true }
      parser.on("--plan PATH", "Approved plan path") { |path| options[:plan] = path }
    end.parse!

    repository_root = File.expand_path("../..", __dir__)
    applier = IonVendoringApply::Applier.new(
      repository_root: repository_root,
      plan_path: options.fetch(:plan),
      apply: options.fetch(:apply)
    )
    applier.run
    puts JSON.pretty_generate(applier.summary)
  rescue ArgumentError, KeyError, JSON::ParserError, Errno::ENOENT => e
    warn "vendoring apply failed: #{e.message}"
    exit 1
  end
end
