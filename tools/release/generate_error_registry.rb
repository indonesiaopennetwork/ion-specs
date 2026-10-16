#!/usr/bin/env ruby

require "date"
require "json"
require "optparse"
require "pathname"
require "yaml"

module IonReleaseErrorRegistry
  module_function

  def build(release_root)
    root = Pathname.new(File.expand_path(release_root))
    [build_error_registry(root)]
  end

  def build_error_registry(root)
    errors = []
    sources = {
      "trade" => ["errors/trade.yaml", /\AION-A\d{4,}\z/],
      "logistics" => ["errors/logistics.yaml", /\AION-B\d{4,}\z/]
    }
    entries_by_sector = {}

    sources.each do |sector, (relative_path, code_pattern)|
      path = root.join(relative_path)
      entries = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
      unless entries.is_a?(Array)
        errors << "#{relative_path}: top level must be an array"
        entries = []
      end
      entries.each do |entry|
        errors << "#{relative_path}: every entry must be an object" unless entry.is_a?(Hash)
        next unless entry.is_a?(Hash)

        errors << "invalid #{sector.capitalize} error code: #{entry['code']}" unless entry["code"].to_s.match?(code_pattern)
        errors << "#{entry['code']}: sector must be #{sector}" unless entry["sector"] == sector
      end
      entries_by_sector[sector] = entries
    end

    entries = sources.keys.flat_map { |sector| entries_by_sector.fetch(sector) }
    codes = entries.map { |entry| entry["code"] }
    codes.group_by { |code| code }.select { |_, values| values.length > 1 }.each_key do |code|
      errors << "duplicate error code: #{code}"
    end
    registry = {
      "_generated" => "Do not edit directly. Run tools/release/generate_error_registry.rb --write releases/#{root.basename}.",
      "_sources" => sources.values.map(&:first),
      "version" => "2.0.0",
      "sectors" => sources.keys,
      "count" => entries.length,
      "bySector" => entries_by_sector.transform_values(&:length),
      "errors" => entries
    }
    [root.join("errors/registry.json"), registry, errors]
  rescue Errno::ENOENT, Psych::SyntaxError => e
    [root.join("errors/registry.json"), {}, [e.message.lines.first.strip]]
  end

end

if $PROGRAM_NAME == __FILE__
  options = { write: false }
  OptionParser.new do |parser|
    parser.on("--write", "Write deterministic registry files") { options[:write] = true }
  end.parse!(ARGV)
  release_root = ARGV.fetch(0, "releases/release1")
  failures = []
  IonReleaseErrorRegistry.build(release_root).each do |path, registry, errors|
    failures.concat(errors)
    rendered = JSON.pretty_generate(registry) + "\n"
    if options[:write]
      path.dirname.mkpath
      path.write(rendered)
      puts "generated #{path}: #{registry['totalPolicies'] || registry['count']} entries"
    elsif !path.file?
      failures << "generated registry is missing: #{path}"
    elsif path.read != rendered
      failures << "generated registry is stale: #{path}"
    else
      puts "generated registry is current: #{path}"
    end
  end
  unless failures.empty?
    failures.each { |failure| warn "ERROR: #{failure}" }
    exit 1
  end
end
