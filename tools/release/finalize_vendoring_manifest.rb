#!/usr/bin/env ruby

require "date"
require "digest"
require "json"
require "optparse"
require "pathname"
require "yaml"

require_relative "validate_offline_refs"
require_relative "validate_artifact_checksums"

module IonVendoringManifest
  LICENSE_ID = "CC-BY-NC-SA-4.0".freeze
  REF_TRANSFORMATION = "Rewrote schema.beckn.io $ref values to Release 1 public vendored URLs.".freeze

  module_function

  def sha256_file(path)
    Digest::SHA256.file(path).hexdigest
  end

  def release_relative(repository_path, release_root)
    Pathname.new(File.expand_path(repository_path)).relative_path_from(Pathname.new(File.expand_path(release_root))).to_s
  end

  def dependency_record(name:, type:, version:, upstream:, target:, release_root:)
    released_sha = sha256_file(target)
    transformations = if released_sha == upstream.fetch("sha256")
                        []
                      elsif type == "protocol"
                        raise ArgumentError, "vendored protocol differs from upstream; do not transform protocol files without explicit approval"
                      else
                        [REF_TRANSFORMATION]
                      end
    {
      "name" => name,
      "type" => type,
      "upstreamVersion" => version,
      "upstreamRepository" => upstream.fetch("repository"),
      "upstreamCommit" => upstream.fetch("commit"),
      "upstreamUrl" => upstream.fetch("rawUrl"),
      "vendoredPath" => release_relative(target, release_root),
      "upstreamSha256" => upstream.fetch("sha256"),
      "releasedSha256" => released_sha,
      "license" => LICENSE_ID,
      "transformations" => transformations
    }
  end

  class Finalizer
    attr_reader :summary

    def initialize(repository_root:, plan_path:, manifest_path:, apply:)
      @repository_root = File.expand_path(repository_root)
      @plan_path = File.expand_path(plan_path, @repository_root)
      @manifest_path = File.expand_path(manifest_path, @repository_root)
      @release_root = File.dirname(@manifest_path)
      @apply = apply
    end

    def run
      plan = JSON.parse(File.read(@plan_path))
      manifest = YAML.safe_load(File.read(@manifest_path), permitted_classes: [Date, Time], aliases: true)
      raise ArgumentError, "vendoring plan is not approved" unless plan["status"] == "approved"
      raise ArgumentError, "release manifest must remain draft" unless manifest["status"] == "draft"

      validator = IonOfflineRefs::Validator.new(@release_root)
      unless validator.validate
        raise ArgumentError, "offline reference validation failed:\n#{validator.errors.join("\n")}"
      end

      dependencies = []
      protocol = plan.fetch("protocol")
      dependencies << IonVendoringManifest.dependency_record(
        name: protocol.fetch("name"),
        type: "protocol",
        version: protocol.fetch("version"),
        upstream: protocol.fetch("upstream"),
        target: repository_path(protocol.fetch("existingCandidate")),
        release_root: @release_root
      )
      plan.fetch("dependencies").each do |dependency|
        dependencies << IonVendoringManifest.dependency_record(
          name: dependency.fetch("name"),
          type: "schema",
          version: dependency.fetch("version"),
          upstream: dependency.fetch("upstream"),
          target: repository_path(dependency.fetch("target")),
          release_root: @release_root
        )
      end

      artifact_checksums = IonArtifactChecksums.artifact_files(Pathname.new(@release_root)).to_h do |relative_path|
        [relative_path, IonVendoringManifest.sha256_file(File.join(@release_root, relative_path))]
      end
      manifest["dependencyStatus"] = "complete"
      manifest["dependencies"] = dependencies
      manifest["artifactChecksums"] = artifact_checksums
      manifest["notes"] = [
        "Draft release envelope created during migration Phase 2.",
        "Beckn dependencies were vendored and the offline reference graph was closed during Phase 4.",
        "Draft URLs are unsupported until the release is published."
      ]

      output = YAML.dump(manifest).sub(/\A---\n/, "")
      output = output.gsub(/^(publishedAt|toolingCommit):[ \t]*$/, '\\1: null')
      File.write(@manifest_path, output) if @apply
      @summary = {
        "mode" => @apply ? "apply" : "dry-run",
        "dependencies" => dependencies.length,
        "transformedDependencies" => dependencies.count { |dependency| !dependency.fetch("transformations").empty? },
        "artifactChecksums" => artifact_checksums.length,
        "offlineDocuments" => validator.document_count,
        "offlineReferences" => validator.reference_count
      }
    end

    private

    def repository_path(path)
      expanded = File.expand_path(path, @repository_root)
      prefix = "#{@repository_root}#{File::SEPARATOR}"
      raise ArgumentError, "path escapes repository: #{path}" unless expanded.start_with?(prefix)
      raise ArgumentError, "missing vendored file: #{path}" unless File.file?(expanded)
      expanded
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    options = { apply: false }
    OptionParser.new do |parser|
      parser.banner = "Usage: ruby tools/release/finalize_vendoring_manifest.rb [--apply]"
      parser.on("--apply", "Write the verified dependency records (default: dry-run)") { options[:apply] = true }
    end.parse!
    repository_root = File.expand_path("../..", __dir__)
    finalizer = IonVendoringManifest::Finalizer.new(
      repository_root: repository_root,
      plan_path: "tools/release/release1-vendoring-plan.json",
      manifest_path: "releases/release1/release.yaml",
      apply: options.fetch(:apply)
    )
    finalizer.run
    puts JSON.pretty_generate(finalizer.summary)
  rescue ArgumentError, KeyError, JSON::ParserError, Errno::ENOENT, Psych::SyntaxError => e
    warn "manifest finalization failed: #{e.message}"
    exit 1
  end
end
