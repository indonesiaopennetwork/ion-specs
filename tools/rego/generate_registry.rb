#!/usr/bin/env ruby

require "json"
require "optparse"
require "pathname"
require "yaml"
require_relative "lib/rule_inventory"

module IonRegoRegistry
  module_function

  def build(release_root)
    root = Pathname.new(File.expand_path(release_root))
    inventory, errors = IonRegoInventory.build(root)
    release = inventory["release"]
    registry = {
      "_generated" => "Do not edit directly. Run tools/rego/generate_registry.rb --write releases/#{root.basename}.",
      "schemaVersion" => 1,
      "release" => release,
      "publicQuery" => inventory["publicQuery"],
      "count" => inventory.fetch("rules", []).length,
      "rules" => inventory.fetch("rules", [])
    }
    [root.join("rules/registry.json"), registry, errors]
  end

  def render(registry)
    JSON.pretty_generate(registry) + "\n"
  end

  def sync(release_root, write: false, out: $stdout)
    path, registry, errors = build(release_root)
    rendered = render(registry)
    if errors.empty? && write
      path.dirname.mkpath
      path.write(rendered)
      out.puts "generated #{path}: #{registry['count']} rules"
    elsif errors.empty? && !path.file?
      errors << "generated rule registry is missing: #{path}; run tools/rego/generate_registry.rb --write #{release_root}"
    elsif errors.empty? && path.read != rendered
      errors << "generated rule registry is stale: #{path}; run tools/rego/generate_registry.rb --write #{release_root}"
    elsif errors.empty?
      out.puts "generated rule registry is current: #{path}"
    end
    [path, registry, errors]
  end
end

if $PROGRAM_NAME == __FILE__
  options = { write: false }
  OptionParser.new do |parser|
    parser.on("--write", "Write the deterministic rule registry") { options[:write] = true }
  end.parse!(ARGV)
  release_root = ARGV.fetch(0, "releases/release2")
  _path, _registry, errors = IonRegoRegistry.sync(release_root, write: options[:write])
  unless errors.empty?
    errors.each { |failure| warn "ERROR: #{failure}" }
    exit 1
  end
end
