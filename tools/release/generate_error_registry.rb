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
    path = root.join("errors/trade.yaml")
    errors = []
    entries = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
    unless entries.is_a?(Array)
      errors << "errors/trade.yaml: top level must be an array"
      entries = []
    end
    codes = entries.map { |entry| entry["code"] }
    codes.group_by { |code| code }.select { |_, values| values.length > 1 }.each_key do |code|
      errors << "duplicate error code: #{code}"
    end
    entries.each do |entry|
      errors << "invalid Trade error code: #{entry['code']}" unless entry["code"].to_s.match?(/\AION-A\d{4,}\z/)
    end
    registry = {
      "_generated" => "Do not edit directly. Run tools/release/generate_error_registry.rb --write releases/#{root.basename}.",
      "_source" => "errors/trade.yaml",
      "version" => "2.0.0",
      "sector" => "trade",
      "count" => entries.length,
      "errors" => entries
    }
    [root.join("errors/registry.json"), registry, errors]
  rescue Errno::ENOENT, Psych::SyntaxError => e
    [root.join("errors/registry.json"), {}, ["errors/trade.yaml: #{e.message.lines.first.strip}"]]
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
