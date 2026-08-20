#!/usr/bin/env ruby

require "date"
require "json"
require "time"
require "yaml"

module IonReleaseManifest
  CONTENT_AREAS = %w[ionApi common trade logistics hospitality finance].freeze
  CONTENT_STATES = %w[review-required validation-pending validated excluded].freeze
  RELEASE_STATUSES = %w[draft published].freeze
  DEPENDENCY_STATUSES = %w[incomplete complete].freeze
  SHA1 = /\A[0-9a-f]{40}\z/.freeze
  SHA256 = /\A[0-9a-f]{64}\z/.freeze
  URL_PREFIX = "https://schema.ion.id/releases/".freeze
  DEPENDENCY_FIELDS = %w[
    name type upstreamVersion upstreamRepository upstreamCommit upstreamUrl
    vendoredPath upstreamSha256 releasedSha256 license transformations
  ].freeze

  module_function

  def validate(data)
    errors = []
    unless data.is_a?(Hash)
      return ["manifest root must be an object"]
    end

    required = %w[
      schemaVersion release name status publishedAt publicBaseUrl sourceBranch
      contentStatus dependencyStatus dependencies artifactChecksums
    ]
    missing = required.reject { |key| data.key?(key) }
    errors << "missing required fields: #{missing.join(', ')}" unless missing.empty?

    release = data["release"]
    expected_name = release.is_a?(Integer) && release.positive? ? "release#{release}" : nil
    errors << "schemaVersion must be 1" unless data["schemaVersion"] == 1
    errors << "release must be a positive integer" unless expected_name
    errors << "name must equal #{expected_name}" if expected_name && data["name"] != expected_name

    status = data["status"]
    errors << "status must be draft or published" unless RELEASE_STATUSES.include?(status)
    errors << "sourceBranch must be main" unless data["sourceBranch"] == "main"

    if expected_name
      expected_url = "#{URL_PREFIX}#{expected_name}/"
      errors << "publicBaseUrl must equal #{expected_url}" unless data["publicBaseUrl"] == expected_url
    end

    validate_content_status(data["contentStatus"], status, errors)
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
    elsif status == "published"
      validate_published(data, dependencies, checksums, dependency_status, errors)
    end

    errors
  end

  def validate_content_status(content, release_status, errors)
    unless content.is_a?(Hash)
      errors << "contentStatus must be an object"
      return
    end

    missing = CONTENT_AREAS.reject { |area| content.key?(area) }
    extra = content.keys - CONTENT_AREAS
    errors << "contentStatus missing: #{missing.join(', ')}" unless missing.empty?
    errors << "contentStatus has unknown areas: #{extra.join(', ')}" unless extra.empty?

    content.each do |area, state|
      errors << "invalid content state for #{area}: #{state}" unless CONTENT_STATES.include?(state)
    end

    return unless release_status == "published"

    errors << "published ionApi must be validated" unless content["ionApi"] == "validated"
    content.each do |area, state|
      next if area == "ionApi"
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
    errors << "dependency #{index} transformations must be an array" unless dependency["transformations"].is_a?(Array)
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
  if ARGV.length != 1
    warn "Usage: ruby tools/release/validate_manifest.rb <release.yaml>"
    exit 2
  end

  begin
    errors = IonReleaseManifest.validate(IonReleaseManifest.load(ARGV.fetch(0)))
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
