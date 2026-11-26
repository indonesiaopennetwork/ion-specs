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
    fixtures = Dir.glob(rules_root.join("tests/fixtures/**/*.json").to_s).sort.reject do |path|
      path.end_with?(".expected.json")
    end

    missing = []
    missing << "production Rego modules" if production_files.empty?
    missing << "Rego unit tests" if test_files.empty?
    missing << "JSON smoke fixtures" if fixtures.empty?
    unless missing.empty?
      err.puts "Rego scaffold is incomplete: missing #{missing.join(', ')}"
      return false
    end

    return false unless run(
      [opa, "fmt", "--fail", *production_files, *test_files],
      "format",
      out,
      err,
      echo_stdout: false
    )
    return false unless run([opa, "check", "--strict", *production_files], "strict compile", out, err)
    return false unless run([opa, "test", "--fail-on-empty", "--verbose", *production_files, *test_files], "unit tests", out, err)

    fixtures.each do |fixture|
      actual, evaluation_error = evaluate(opa, rules_root, fixture)
      if evaluation_error
        err.puts "Rego smoke evaluation failed for #{fixture}: #{evaluation_error}"
        return false
      end
      expected_path = fixture.sub(/\.json\z/, ".expected.json")
      expected = File.file?(expected_path) ? JSON.parse(File.read(expected_path)) : EXPECTED_RESULT
      unless normalized_result(actual) == normalized_result(expected)
        err.puts "unexpected Rego result for #{fixture}: expected #{expected.inspect}, got #{actual.inspect}"
        return false
      end
      out.puts "Rego smoke evaluation passed: #{Pathname.new(fixture).relative_path_from(root)}"
    end

    flow_examples = Dir.glob(root.join("flows/**/examples/*.json").to_s).sort
    flow_examples.each do |example|
      actual, evaluation_error = evaluate(opa, rules_root, example)
      if evaluation_error
        err.puts "Rego reference-flow evaluation failed for #{example}: #{evaluation_error}"
        return false
      end
      unless normalized_result(actual) == EXPECTED_RESULT
        err.puts "existing Release 2 example violates Rego rules: #{example}: #{actual.inspect}"
        return false
      end
    end
    out.puts "Rego reference-flow regression passed: #{flow_examples.length} examples"

    out.puts "Release 2 Rego scaffold validation passed: #{root}"
    true
  end

  def normalized_result(result)
    return result unless result.is_a?(Hash) && result["violations"].is_a?(Array)

    result.merge("violations" => result["violations"].sort_by { |violation| JSON.generate(violation) })
  end

  def evaluate(opa, rules_root, input_path)
    command = [
      opa, "eval", "--fail", "--format=json",
      "--data", rules_root.join("rego").to_s,
      "--data", rules_root.join("data/data.json").to_s,
      "--input", input_path,
      PUBLIC_QUERY
    ]
    stdout, stderr, status = Open3.capture3(*command)
    return [nil, stderr.strip] unless status.success?

    response = JSON.parse(stdout)
    [response.fetch("result").fetch(0).fetch("expressions").fetch(0).fetch("value"), nil]
  rescue JSON::ParserError, KeyError, IndexError, NoMethodError => e
    [nil, "invalid OPA output: #{e.message}"]
  end

  def run(command, label, out, err, echo_stdout: true)
    stdout, stderr, status = Open3.capture3(*command)
    unless status.success?
      err.puts "Rego #{label} failed"
      err.puts stdout unless stdout.empty?
      err.puts stderr unless stderr.empty?
      return false
    end
    out.print(stdout) if echo_stdout && !stdout.empty?
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
