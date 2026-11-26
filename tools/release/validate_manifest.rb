#!/usr/bin/env ruby

require "date"
require "json"
require "time"
require "yaml"

module IonReleaseManifest
  BASE_CONTENT_AREAS = %w[ionApi common trade logistics hospitality finance flows errors].freeze
  CONTENT_AREAS_BY_SCHEMA_VERSION = {
    1 => BASE_CONTENT_AREAS,
    2 => (BASE_CONTENT_AREAS + %w[rules]).freeze
  }.freeze
  CONTENT_STATES = %w[review-required validation-pending validated excluded].freeze
  RELEASE_STATUSES = %w[draft published].freeze
  DEPENDENCY_STATUSES = %w[incomplete complete].freeze
  IMPLEMENTATION_MATURITIES = %w[implementation-ready reference preview excluded].freeze
  SHA1 = /\A[0-9a-f]{40}\z/.freeze
  SHA256 = /\A[0-9a-f]{64}\z/.freeze
  URL_PREFIX = "https://schema.ion.id/".freeze
  DEPENDENCY_FIELDS = %w[
    name type upstreamVersion upstreamRepository upstreamCommit upstreamUrl
    vendoredPath upstreamSha256 releasedSha256 license transformations
  ].freeze
  MAINTAINED_ARTIFACT_FIELDS = %w[
    name type path upstreamVersion upstreamRepository upstreamCommit upstreamUrl
    upstreamSha256 releasedSha256 license transformations
  ].freeze

  module_function

  def validate(data)
    errors = []
    unless data.is_a?(Hash)
      return ["manifest root must be an object"]
    end

    required = %w[
      schemaVersion release name status publishedAt publicBaseUrl sourceBranch
      contentStatus dependencyStatus dependencies maintainedArtifacts implementationGuidance
      artifactChecksums
    ]
    missing = required.reject { |key| data.key?(key) }
    errors << "missing required fields: #{missing.join(', ')}" unless missing.empty?

    release = data["release"]
    expected_name = release.is_a?(Integer) && release.positive? ? "release#{release}" : nil
    schema_version = data["schemaVersion"]
    unless CONTENT_AREAS_BY_SCHEMA_VERSION.key?(schema_version)
      errors << "schemaVersion must be 1 or 2"
    end
    errors << "release must be a positive integer" unless expected_name
    errors << "name must equal #{expected_name}" if expected_name && data["name"] != expected_name

    status = data["status"]
    errors << "status must be draft or published" unless RELEASE_STATUSES.include?(status)
    errors << "sourceBranch must be main" unless data["sourceBranch"] == "main"

    if expected_name
      expected_url = "#{URL_PREFIX}#{expected_name}/"
      errors << "publicBaseUrl must equal #{expected_url}" unless data["publicBaseUrl"] == expected_url
    end

    content_areas = CONTENT_AREAS_BY_SCHEMA_VERSION.fetch(schema_version, [])
    validate_content_status(data["contentStatus"], status, content_areas, errors)
    dependency_status = data["dependencyStatus"]
    unless DEPENDENCY_STATUSES.include?(dependency_status)
      errors << "dependencyStatus must be incomplete or complete"
    end

    dependencies = data["dependencies"]
    if dependencies.is_a?(Array)
      dependencies.each_with_index do |dependency, index|
        validate_dependency(dependency, index, errors)
      end
    else
      errors << "dependencies must be an array"
    end

    maintained_artifacts = data["maintainedArtifacts"]
    if maintained_artifacts.is_a?(Array)
      maintained_artifacts.each_with_index do |artifact, index|
        validate_maintained_artifact(artifact, index, errors)
      end
    else
      errors << "maintainedArtifacts must be an array"
    end

    validate_implementation_guidance(data["implementationGuidance"], content_areas, errors)

    checksums = data["artifactChecksums"]
    if checksums.is_a?(Hash)
      checksums.each do |path, checksum|
        errors << "unsafe artifactChecksums path: #{path}" unless safe_relative_path?(path)
        errors << "invalid SHA-256 for artifactChecksums #{path}" unless checksum.to_s.match?(SHA256)
      end
    else
      errors << "artifactChecksums must be an object"
    end

    if status == "draft"
      errors << "draft publishedAt must be null" unless data["publishedAt"].nil?
      if checksums.is_a?(Hash)
        checksums.each_key do |path|
          errors << "draft artifactChecksums path must be under schema/vendored/: #{path}" unless path.to_s.start_with?("schema/vendored/")
        end
      end
    elsif status == "published"
      validate_published(data, dependencies, checksums, dependency_status, errors)
    end

    errors
  end

  def validate_for_publication(data)
    errors = validate(data)
    errors << "release status must be published" unless data.is_a?(Hash) && data["status"] == "published"
    errors
  end

  def validate_content_status(content, release_status, content_areas, errors)
    unless content.is_a?(Hash)
      errors << "contentStatus must be an object"
      return
    end

    missing = content_areas.reject { |area| content.key?(area) }
    extra = content.keys - content_areas
    errors << "contentStatus missing: #{missing.join(', ')}" unless missing.empty?
    errors << "contentStatus has unknown areas: #{extra.join(', ')}" unless extra.empty?

    content.each do |area, state|
      errors << "invalid content state for #{area}: #{state}" unless CONTENT_STATES.include?(state)
    end

    return unless release_status == "published"

    content.each do |area, state|
      errors << "published #{area} must be validated or excluded" unless %w[validated excluded].include?(state)
    end
  end

  def validate_dependency(dependency, index, errors)
    unless dependency.is_a?(Hash)
      errors << "dependency #{index} must be an object"
      return
    end

    missing = DEPENDENCY_FIELDS.reject { |field| dependency.key?(field) }
    errors << "dependency #{index} missing: #{missing.join(', ')}" unless missing.empty?
    errors << "dependency #{index} type must be protocol or schema" unless %w[protocol schema].include?(dependency["type"])
    errors << "dependency #{index} upstreamCommit must be a 40-character commit" unless dependency["upstreamCommit"].to_s.match?(SHA1)
    %w[upstreamSha256 releasedSha256].each do |field|
      errors << "dependency #{index} #{field} must be SHA-256" unless dependency[field].to_s.match?(SHA256)
    end
    unless safe_relative_path?(dependency["vendoredPath"])
      errors << "dependency #{index} vendoredPath must be release-relative"
    end
    dependency_path = dependency["vendoredPath"].to_s
    unless dependency_path.start_with?("schema/vendored/")
      errors << "dependency #{index} vendoredPath must be under schema/vendored/"
    end
    errors << "dependency #{index} transformations must be an array" unless dependency["transformations"].is_a?(Array)
  end

  def validate_maintained_artifact(artifact, index, errors)
    unless artifact.is_a?(Hash)
      errors << "maintained artifact #{index} must be an object"
      return
    end

    missing = MAINTAINED_ARTIFACT_FIELDS.reject { |field| artifact.key?(field) }
    errors << "maintained artifact #{index} missing: #{missing.join(', ')}" unless missing.empty?
    errors << "maintained artifact #{index} type must be protocol" unless artifact["type"] == "protocol"
    errors << "maintained artifact #{index} upstreamCommit must be a 40-character commit" unless artifact["upstreamCommit"].to_s.match?(SHA1)
    %w[upstreamSha256 releasedSha256].each do |field|
      errors << "maintained artifact #{index} #{field} must be SHA-256" unless artifact[field].to_s.match?(SHA256)
    end
    unless safe_relative_path?(artifact["path"])
      errors << "maintained artifact #{index} path must be release-relative"
    end
    unless artifact["path"].to_s.start_with?("schema/core/")
      errors << "maintained artifact #{index} path must be under schema/core/"
    end
    unless artifact["transformations"].is_a?(Array) && !artifact["transformations"].empty?
      errors << "maintained artifact #{index} transformations must be a non-empty array"
    end
  end

  def validate_implementation_guidance(guidance, content_areas, errors)
    unless guidance.is_a?(Hash)
      errors << "implementationGuidance must be an object"
      return
    end

    extra = guidance.keys - %w[primaryProfile areas]
    errors << "implementationGuidance has unknown fields: #{extra.join(', ')}" unless extra.empty?
    primary = guidance["primaryProfile"]
    unless primary.is_a?(Hash)
      errors << "implementationGuidance.primaryProfile must be an object"
    else
      required = %w[id path maturity description]
      missing = required.reject { |field| primary.key?(field) }
      errors << "implementationGuidance.primaryProfile missing: #{missing.join(', ')}" unless missing.empty?
      errors << "implementationGuidance.primaryProfile path must be under flows/" unless safe_relative_path?(primary["path"]) && primary["path"].start_with?("flows/")
      unless IMPLEMENTATION_MATURITIES.include?(primary["maturity"])
        errors << "implementationGuidance.primaryProfile has invalid maturity: #{primary['maturity']}"
      end
    end

    areas = guidance["areas"]
    unless areas.is_a?(Hash) && !areas.empty?
      errors << "implementationGuidance.areas must be a non-empty object"
      return
    end
    areas.each do |area, value|
      errors << "implementationGuidance.areas has unknown area: #{area}" unless content_areas.include?(area)
      unless value.is_a?(Hash)
        errors << "implementationGuidance.areas.#{area} must be an object"
        next
      end
      missing = %w[maturity notes].reject { |field| value.key?(field) }
      errors << "implementationGuidance.areas.#{area} missing: #{missing.join(', ')}" unless missing.empty?
      unless IMPLEMENTATION_MATURITIES.include?(value["maturity"])
        errors << "implementationGuidance.areas.#{area} has invalid maturity: #{value['maturity']}"
      end
      if value.key?("productionRecommended") && ![true, false].include?(value["productionRecommended"])
        errors << "implementationGuidance.areas.#{area}.productionRecommended must be boolean"
      end
      notes = value["notes"]
      unless notes.is_a?(Array) && !notes.empty? && notes.all? { |note| note.is_a?(String) && !note.empty? }
        errors << "implementationGuidance.areas.#{area}.notes must be a non-empty string array"
      end
    end

    if primary.is_a?(Hash) && areas.dig("trade", "primaryProfile") != primary["id"]
      errors << "Trade primaryProfile must match implementationGuidance.primaryProfile.id"
    end
  end

  def validate_published(data, dependencies, checksums, dependency_status, errors)
    begin
      Time.iso8601(data["publishedAt"].to_s)
    rescue ArgumentError
      errors << "published publishedAt must be an ISO 8601 date-time"
    end
    errors << "published dependencyStatus must be complete" unless dependency_status == "complete"
    errors << "published dependencies must not be empty" if dependencies.is_a?(Array) && dependencies.empty?
    errors << "published artifactChecksums must not be empty" if checksums.is_a?(Hash) && checksums.empty?
    errors << "published toolingCommit must be a 40-character commit" unless data["toolingCommit"].to_s.match?(SHA1)
  end

  def safe_relative_path?(path)
    return false unless path.is_a?(String) && !path.empty?
    return false if path.start_with?("/")

    !path.split("/").include?("..")
  end

  def load(path)
    YAML.load_file(path)
  rescue Psych::SyntaxError => e
    raise ArgumentError, "invalid YAML: #{e.message}"
  end
end

if $PROGRAM_NAME == __FILE__
  require_published = ARGV.delete("--require-published")
  if ARGV.length != 1
    warn "Usage: ruby tools/release/validate_manifest.rb [--require-published] <release.yaml>"
    exit 2
  end

  begin
    manifest = IonReleaseManifest.load(ARGV.fetch(0))
    errors = if require_published
               IonReleaseManifest.validate_for_publication(manifest)
             else
               IonReleaseManifest.validate(manifest)
             end
  rescue ArgumentError => e
    warn "ERROR: #{e.message}"
    exit 1
  end

  if errors.empty?
    puts "valid release manifest: #{ARGV.fetch(0)}"
    exit 0
  end

  errors.each { |error| warn "ERROR: #{error}" }
  exit 1
end
