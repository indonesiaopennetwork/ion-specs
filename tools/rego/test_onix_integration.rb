#!/usr/bin/env ruby

require "json"
require "open3"
require "optparse"
require "pathname"
require "tempfile"
require "tmpdir"

module IonOnixIntegration
  module_function

  def run(onix_root:, out: $stdout, err: $stderr)
    repository_root = Pathname.new(File.expand_path("../..", __dir__))
    onix = Pathname.new(File.expand_path(onix_root))
    expected_revision = repository_root.join("tools/rego/onix-revision").read.strip

    unless onix.join("go.mod").file? && onix.join("pkg/plugin/implementation/opapolicychecker").directory?
      err.puts "not a beckn-onix checkout: #{onix}"
      return false
    end

    revision, git_error, git_status = Open3.capture3("git", "-C", onix.to_s, "rev-parse", "HEAD")
    unless git_status.success?
      err.puts "could not read ONIX revision: #{git_error.strip}"
      return false
    end
    if revision.strip != expected_revision
      err.puts "ONIX revision mismatch: expected #{expected_revision}, got #{revision.strip}"
      return false
    end

    target = onix.join("pkg/plugin/implementation/opapolicychecker/ion_release2_integration_test.go")
    source = repository_root.join("tools/rego/onix_integration_test.go")
    overlay = { "Replace" => { target.to_s => source.to_s } }

    Dir.mktmpdir("ion-onix-go-cache") do |go_cache|
      Tempfile.create(["ion-onix-overlay", ".json"]) do |file|
        file.write(JSON.generate(overlay))
        file.flush
        command = [
          "go", "test", "-overlay", file.path,
          "./pkg/plugin/implementation/opapolicychecker",
          "-run", "^TestIONRelease2Integration$", "-count=1", "-v"
        ]
        environment = {
          "GOCACHE" => go_cache,
          "ION_SPECS_ROOT" => repository_root.to_s
        }
        out.puts "Testing ION Release 2 bundle with ONIX #{expected_revision}"
        success = system(environment, *command, chdir: onix.to_s, out: out, err: err)
        return false unless success
      end
    end

    out.puts "Optional ONIX integration passed"
    true
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/rego/test_onix_integration.rb --onix-root PATH"
    opts.on("--onix-root PATH", "Pinned beckn-onix checkout") { |value| options[:onix_root] = value }
  end

  begin
    parser.parse!
    options[:onix_root] ||= ENV["ONIX_ROOT"]
    raise OptionParser::MissingArgument, "--onix-root or ONIX_ROOT is required" if options[:onix_root].to_s.empty?
  rescue OptionParser::ParseError => e
    warn e.message
    warn parser
    exit 2
  end

  exit(IonOnixIntegration.run(**options) ? 0 : 1)
end
