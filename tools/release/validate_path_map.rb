#!/usr/bin/env ruby

require "json"

module IonReleasePathMap
  KINDS = %w[api vendored-protocol common-pack trade-pack].freeze
  PATH_STATUSES = %w[approved proposed].freeze
  CONTENT_STATUSES = %w[review-required validation-pending provenance-pending].freeze
  REQUIRED_MAPPING_FIELDS = %w[
    kind source target publicUrl pathStatus contentStatus
  ].freeze

  module_function

  def validate(data, repository_root: nil)
    errors = []
    return ["path map root must be an object"] unless data.is_a?(Hash)

    release = data["release"]
    release_name = release.is_a?(Integer) && release.positive? ? "release#{release}" : nil
    errors << "schemaVersion must be 1" unless data["schemaVersion"] == 1
    errors << "release must be a positive integer" unless release_name

    expected_base = release_name && "https://schema.ion.id/releases/#{release_name}/"
    errors << "publicBaseUrl must equal #{expected_base}" if expected_base && data["publicBaseUrl"] != expected_base

    mappings = data["mappings"]
    unless mappings.is_a?(Array) && !mappings.empty?
      errors << "mappings must be a non-empty array"
      return errors
    end

    mappings.each_with_index do |mapping, index|
      validate_mapping(mapping, index, release_name, expected_base, repository_root, errors)
    end

    %w[source target publicUrl].each do |field|
      values = mappings.each_with_object([]) do |mapping, result|
        result << mapping[field] if mapping.is_a?(Hash)
      end
      errors << "duplicate #{field} mappings" unless values.uniq.size == values.size
    end

    errors
  end

  def validate_mapping(mapping, index, release_name, public_base, repository_root, errors)
    unless mapping.is_a?(Hash)
      errors << "mapping #{index} must be an object"
      return
    end

    missing = REQUIRED_MAPPING_FIELDS.reject { |field| mapping.key?(field) }
    errors << "mapping #{index} missing: #{missing.join(', ')}" unless missing.empty?
    errors << "mapping #{index} has invalid kind" unless KINDS.include?(mapping["kind"])
    errors << "mapping #{index} has invalid pathStatus" unless PATH_STATUSES.include?(mapping["pathStatus"])
    errors << "mapping #{index} has invalid contentStatus" unless CONTENT_STATUSES.include?(mapping["contentStatus"])

    source = mapping["source"]
    target = mapping["target"]
    public_url = mapping["publicUrl"]
    errors << "mapping #{index} source must be repository-relative" unless safe_relative_path?(source)
    errors << "mapping #{index} target must be repository-relative" unless safe_relative_path?(target)

    if release_name && target.is_a?(String)
      target_prefix = "releases/#{release_name}/"
      errors << "mapping #{index} target must stay under #{target_prefix}" unless target.start_with?(target_prefix)
      suffix = target.delete_prefix(target_prefix)
      expected_url = "#{public_base}#{suffix}"
      expected_url += "/" if public_url.to_s.end_with?("/") && !expected_url.end_with?("/")
      errors << "mapping #{index} publicUrl does not mirror target" unless public_url == expected_url
    end

    if repository_root && safe_relative_path?(source)
      errors << "mapping #{index} source does not exist: #{source}" unless File.exist?(File.join(repository_root, source))
    end
  end

  def safe_relative_path?(path)
    path.is_a?(String) && !path.empty? && !path.start_with?("/") && !path.split("/").include?("..")
  end

  def load(path)
    JSON.parse(File.read(path))
  rescue JSON::ParserError => e
    raise ArgumentError, "invalid JSON: #{e.message}"
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length != 1
    warn "Usage: ruby tools/release/validate_path_map.rb <path-map.json>"
    exit 2
  end

  begin
    path = File.expand_path(ARGV.fetch(0))
    repository_root = File.expand_path("../..", __dir__)
    errors = IonReleasePathMap.validate(
      IonReleasePathMap.load(path),
      repository_root: repository_root
    )
  rescue ArgumentError => e
    warn "ERROR: #{e.message}"
    exit 1
  end

  if errors.empty?
    puts "valid release path map: #{ARGV.fetch(0)}"
    exit 0
  end

  errors.each { |error| warn "ERROR: #{error}" }
  exit 1
end
