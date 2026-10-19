#!/usr/bin/env ruby

require "pathname"
require "yaml"

module IonReleaseScope
  FORBIDDEN_FLAT_SCHEMA_PATHS = %w[core common extension vendored].freeze

  CONTENT_PATHS = {
    "ionApi" => ["schema/core/api/*/ion-additional.yaml"],
    "common" => ["schema/common"],
    "trade" => ["schema/extension/trade"],
    "logistics" => ["schema/extension/logistics"],
    "hospitality" => ["schema/extension/hospitality"],
    "finance" => ["schema/extension/finance"],
    "flows" => ["flows/trade", "flows/logistics", "flows/hospitality", "flows/finance"],
    "errors" => ["errors"]
  }.freeze

  SECTOR_FLOW_PATHS = {
    "trade" => ["flows/trade"],
    "logistics" => ["flows/logistics"],
    "hospitality" => ["flows/hospitality"],
    "finance" => ["flows/finance"]
  }.freeze

  module_function

  def validate(release_root, manifest = nil)
    root = Pathname.new(File.expand_path(release_root))
    manifest ||= YAML.safe_load(File.read(root.join("release.yaml")), aliases: true)
    statuses = manifest.fetch("contentStatus", {})
    errors = []

    FORBIDDEN_FLAT_SCHEMA_PATHS.each do |directory|
      path = root.join(directory)
      errors << "schema content must be nested under schema/: #{directory}" if path.exist?
    end

    if root.join("policies").exist?
      errors << "shared policies must not be copied into a release: policies"
    end

    CONTENT_PATHS.each do |area, patterns|
      matches = patterns.flat_map { |pattern| matching_paths(root, pattern) }.uniq
      case statuses[area]
      when "excluded"
        matches.each do |path|
          errors << "excluded content is present for #{area}: #{Pathname.new(path).relative_path_from(root)}"
        end
      when "validated"
        errors << "validated content is absent for #{area}" if matches.empty?
      end
    end

    SECTOR_FLOW_PATHS.each do |sector, patterns|
      next unless statuses[sector] == "excluded"

      patterns.flat_map { |pattern| matching_paths(root, pattern) }.uniq.each do |path|
        errors << "excluded content is present for #{sector}: #{Pathname.new(path).relative_path_from(root)}"
      end
    end

    errors
  rescue Psych::SyntaxError => e
    ["invalid release manifest: #{e.message.lines.first.strip}"]
  end

  def matching_paths(root, pattern)
    pattern.split("/").reduce([root]) do |bases, segment|
      bases.flat_map do |base|
        if segment.match?(/[?*\[]/)
          next [] unless base.directory?

          base.children.select do |child|
            File.fnmatch?(segment, child.basename.to_s, File::FNM_CASEFOLD)
          end
        else
          candidate = base.join(segment)
          candidate.exist? ? [candidate] : []
        end
      end
    end.map(&:to_s)
  end
end

if $PROGRAM_NAME == __FILE__
  release_root = ARGV.fetch(0, "releases/release1")
  errors = IonReleaseScope.validate(release_root)
  if errors.empty?
    puts "release scope validation passed: #{release_root}"
  else
    warn "release scope validation failed with #{errors.length} error(s):"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
