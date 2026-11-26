#!/usr/bin/env ruby

require "json"
require "open3"
require "optparse"
require "pathname"
require "yaml"
require_relative "check_toolchain"

module IonRegoScaffold
  EXPECTED_RESULT = { "valid" => true, "violations" => [] }.freeze
  PUBLIC_QUERY = "data.ion.release2.result"

  module_function

  def validate(release_root, opa: "opa", out: $stdout, err: $stderr)
    root = Pathname.new(File.expand_path(release_root))
    repository_root = Pathname.new(File.expand_path("../..", __dir__))
    manifest = YAML.safe_load(root.join("release.yaml").read, aliases: true)
    if manifest.fetch("schemaVersion", 1) < 2
      out.puts "Rego scaffold validation not applicable to manifest schema v1: #{root}"
      return true
    end
    return false unless IonRegoToolchain.validate(repository_root: repository_root, opa: opa, out: out, err: err)

    rules_root = root.join("rules")
    production_files = Dir.glob(rules_root.join("rego/**/*.rego").to_s).sort
    test_files = Dir.glob(rules_root.join("tests/**/*_test.rego").to_s).sort
    fixtures = Dir.glob(rules_root.join("tests/fixtures/**/*.json").to_s).sort

    missing = []
    missing << "production Rego modules" if production_files.empty?
    missing << "Rego unit tests" if test_files.empty?
    missing << "JSON smoke fixtures" if fixtures.empty?
    unless missing.empty?
      err.puts "Rego scaffold is incomplete: missing #{missing.join(', ')}"
      return false
    end

    return false unless run([opa, "fmt", "--fail", *production_files, *test_files], "format", out, err)
    return false unless run([opa, "check", "--strict", *production_files], "strict compile", out, err)
    return false unless run([opa, "test", "--fail-on-empty", "--verbose", *production_files, *test_files], "unit tests", out, err)

    fixtures.each do |fixture|
      command = [
        opa, "eval", "--fail", "--format=json",
        "--data", rules_root.join("rego").to_s,
        "--data", rules_root.join("data/data.json").to_s,
        "--input", fixture,
        PUBLIC_QUERY
      ]
      stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        err.puts "Rego smoke evaluation failed for #{fixture}"
        err.puts stderr unless stderr.empty?
        return false
      end

      begin
        response = JSON.parse(stdout)
        actual = response.fetch("result").fetch(0).fetch("expressions").fetch(0).fetch("value")
      rescue JSON::ParserError, KeyError, IndexError, NoMethodError => e
        err.puts "invalid OPA evaluation output for #{fixture}: #{e.message}"
        return false
      end
      unless actual == EXPECTED_RESULT
        err.puts "unexpected Rego result for #{fixture}: #{actual.inspect}"
        return false
      end
      out.puts "Rego smoke evaluation passed: #{Pathname.new(fixture).relative_path_from(root)}"
    end

    out.puts "Release 2 Rego scaffold validation passed: #{root}"
    true
  end

  def run(command, label, out, err)
    stdout, stderr, status = Open3.capture3(*command)
    unless status.success?
      err.puts "Rego #{label} failed"
      err.puts stdout unless stdout.empty?
      err.puts stderr unless stderr.empty?
      return false
    end
    out.print(stdout) unless stdout.empty?
    out.puts "Rego #{label} passed"
    true
  end
end

if $PROGRAM_NAME == __FILE__
  options = { opa: "opa" }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/rego/validate_scaffold.rb [options] RELEASE_ROOT"
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

  exit(IonRegoScaffold.validate(release_root, **options) ? 0 : 1)
end
