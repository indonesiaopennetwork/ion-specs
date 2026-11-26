#!/usr/bin/env ruby

require "open3"
require "optparse"
require "pathname"
require "yaml"
require_relative "check_toolchain"
require_relative "lib/rule_inventory"

module IonRegoSourceValidation
  module_function

  def validate(release_root, opa: "opa", out: $stdout, err: $stderr)
    root = Pathname.new(File.expand_path(release_root))
    manifest = YAML.safe_load(root.join("release.yaml").read, aliases: true)
    if manifest.fetch("schemaVersion", 1) < 2
      out.puts "Rego source validation not applicable to manifest schema v1: #{root}"
      return true
    end

    inventory, errors = IonRegoInventory.build(root)
    unless errors.empty?
      errors.each { |message| err.puts "ERROR: #{message}" }
      return false
    end
    repository_root = Pathname.new(File.expand_path("../..", __dir__))
    return false unless IonRegoToolchain.validate(repository_root: repository_root, opa: opa, out: out, err: err)

    files = inventory.fetch("sourceFiles") + inventory.fetch("testFiles")
    return false unless run([opa, "fmt", "--fail", *files.map(&:to_s)], "format", out, err)
    return false unless run([opa, "check", "--strict", *files.map(&:to_s)], "strict source and test compilation", out, err)

    out.puts "Rego source and metadata validation passed: #{root} (#{inventory.fetch('rules').length} rules)"
    true
  rescue Errno::ENOENT, Psych::SyntaxError => e
    err.puts "ERROR: #{e.message.lines.first.strip}"
    false
  end

  def run(command, label, out, err)
    stdout, stderr, status = Open3.capture3(*command)
    unless status.success?
      err.puts "Rego #{label} failed"
      err.puts stdout unless stdout.empty?
      err.puts stderr unless stderr.empty?
      return false
    end
    out.puts "Rego #{label} passed"
    true
  end
end

if $PROGRAM_NAME == __FILE__
  options = { opa: "opa" }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/rego/validate_sources.rb [options] RELEASE_ROOT"
    opts.on("--opa PATH", "OPA executable; defaults to opa on PATH") { |value| options[:opa] = value }
  end
  begin
    parser.parse!
    release_root = ARGV.fetch(0)
  rescue IndexError, OptionParser::ParseError => e
    warn e.message
    warn parser
    exit 2
  end
  exit(IonRegoSourceValidation.validate(release_root, **options) ? 0 : 1)
end
