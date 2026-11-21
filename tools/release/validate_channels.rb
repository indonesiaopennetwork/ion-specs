#!/usr/bin/env ruby

require "date"
require "optparse"
require "pathname"
require "time"
require "yaml"

module IonReleaseChannels
  RELEASE_NAME = /\Arelease[1-9][0-9]*\z/

  module_function

  def validate(data, releases_root:, require_next: nil)
    errors = []
    return ["channel state root must be an object"] unless data.is_a?(Hash)

    required = %w[schemaVersion current next lts]
    missing = required.reject { |field| data.key?(field) }
    extra = data.keys - required
    errors << "channel state missing: #{missing.join(', ')}" unless missing.empty?
    errors << "channel state has unknown fields: #{extra.join(', ')}" unless extra.empty?
    errors << "schemaVersion must be 1" unless data["schemaVersion"] == 1

    current = data["current"]
    validate_release_name(current, "current", errors) unless current.nil?

    next_entry = data["next"]
    next_release = nil
    if next_entry.nil?
      errors << "next must assign #{require_next}" if require_next
    elsif next_entry.is_a?(Hash)
      next_release = validate_next(next_entry, errors)
      if require_next && next_release != require_next
        errors << "next must assign #{require_next}"
      end
    else
      errors << "next must be null or an object"
    end

    lts = data["lts"]
    lts_releases = []
    if lts.is_a?(Array)
      lts.each_with_index do |entry, index|
        unless entry.is_a?(Hash)
          errors << "lts entry #{index} must be an object"
          next
        end
        missing_lts = %w[release supportedUntil].reject { |field| entry.key?(field) }
        extra_lts = entry.keys - %w[release supportedUntil]
        errors << "lts entry #{index} missing: #{missing_lts.join(', ')}" unless missing_lts.empty?
        errors << "lts entry #{index} has unknown fields: #{extra_lts.join(', ')}" unless extra_lts.empty?
        release = entry["release"]
        validate_release_name(release, "lts entry #{index} release", errors)
        lts_releases << release if release.is_a?(String)
        begin
          Date.iso8601(entry["supportedUntil"].to_s)
        rescue Date::Error
          errors << "lts entry #{index} supportedUntil must be an ISO 8601 date"
        end
      end
    else
      errors << "lts must be an array"
    end

    assigned = [current, next_release, *lts_releases].compact
    duplicates = assigned.group_by(&:itself).select { |_, entries| entries.length > 1 }.keys
    duplicates.each { |release| errors << "release occupies more than one channel: #{release}" }
    assigned.uniq.each { |release| validate_published_release(release, releases_root, errors) }
    errors
  end

  def validate_next(entry, errors)
    required = %w[release assignedAt minimumStabilizationDays eligibleForCurrentAt]
    missing = required.reject { |field| entry.key?(field) }
    extra = entry.keys - required
    errors << "next missing: #{missing.join(', ')}" unless missing.empty?
    errors << "next has unknown fields: #{extra.join(', ')}" unless extra.empty?

    release = entry["release"]
    validate_release_name(release, "next release", errors)
    days = entry["minimumStabilizationDays"]
    errors << "next minimumStabilizationDays must be a positive integer" unless days.is_a?(Integer) && days.positive?

    assigned_at = parse_time(entry["assignedAt"], "next assignedAt", errors)
    eligible_at = parse_time(entry["eligibleForCurrentAt"], "next eligibleForCurrentAt", errors)
    if assigned_at && eligible_at && days.is_a?(Integer) && days.positive?
      expected = assigned_at + (days * 86_400)
      errors << "next eligibleForCurrentAt must equal assignedAt plus minimumStabilizationDays" unless eligible_at == expected
    end
    release
  end

  def validate_release_name(value, label, errors)
    errors << "#{label} must be a release name" unless value.is_a?(String) && value.match?(RELEASE_NAME)
  end

  def parse_time(value, label, errors)
    Time.iso8601(value.to_s)
  rescue ArgumentError
    errors << "#{label} must be an ISO 8601 date-time"
    nil
  end

  def validate_published_release(release, releases_root, errors)
    manifest_path = Pathname.new(releases_root).join(release, "release.yaml")
    unless manifest_path.file?
      errors << "channel release manifest does not exist: #{release}"
      return
    end
    manifest = YAML.safe_load(File.read(manifest_path), permitted_classes: [Date, Time], aliases: true)
    errors << "channel release must be published: #{release}" unless manifest["status"] == "published"
  rescue Psych::SyntaxError => e
    errors << "invalid channel release manifest #{release}: #{e.message.lines.first.strip}"
  end
end

if $PROGRAM_NAME == __FILE__
  options = { require_next: nil }
  OptionParser.new do |parser|
    parser.on("--require-next RELEASE") { |value| options[:require_next] = value }
  end.parse!(ARGV)
  channels_path = Pathname.new(File.expand_path(ARGV.fetch(0, "releases/channels.yaml")))
  unless channels_path.file?
    warn "channel state does not exist: #{channels_path}"
    exit 1
  end

  begin
    data = YAML.safe_load(File.read(channels_path), permitted_classes: [Date, Time], aliases: true)
    errors = IonReleaseChannels.validate(
      data,
      releases_root: channels_path.dirname,
      require_next: options[:require_next]
    )
  rescue Psych::SyntaxError => e
    errors = ["invalid channel state: #{e.message.lines.first.strip}"]
  end

  if errors.empty?
    puts "release channel validation passed: #{channels_path}"
  else
    warn "release channel validation failed with #{errors.length} error(s):"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
