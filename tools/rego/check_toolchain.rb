#!/usr/bin/env ruby

require "open3"
require "optparse"
require "pathname"

module IonRegoToolchain
  module_function

  def pinned_version(repository_root)
    Pathname.new(repository_root).join("tools/rego/opa-version").read.strip
  end

  def executable_path(candidate, path_env = ENV.fetch("PATH", ""))
    return candidate if candidate.include?(File::SEPARATOR) && File.file?(candidate) && File.executable?(candidate)

    path_env.split(File::PATH_SEPARATOR).each do |directory|
      path = File.join(directory, candidate)
      return path if File.file?(path) && File.executable?(path)
    end
    nil
  end

  def validate(repository_root:, opa: "opa", out: $stdout, err: $stderr, path_env: ENV.fetch("PATH", ""))
    expected = pinned_version(repository_root)
    executable = executable_path(opa, path_env)
    unless executable
      err.puts "OPA executable not found: #{opa}"
      err.puts "Install OPA #{expected} or pass --opa /absolute/path/to/opa."
      return false
    end

    stdout, stderr, status = Open3.capture3(executable, "version")
    unless status.success?
      err.puts "failed to run #{executable} version"
      err.puts stderr unless stderr.empty?
      return false
    end

    actual = stdout[/^Version:\s+(\S+)/, 1]
    unless actual
      err.puts "could not parse OPA version output from #{executable}"
      return false
    end
    unless actual == expected
      err.puts "OPA version mismatch: expected #{expected}, got #{actual}"
      return false
    end

    out.puts "OPA toolchain check passed: #{actual} (#{executable})"
    true
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repository_root: File.expand_path("../..", __dir__),
    opa: "opa"
  }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/rego/check_toolchain.rb [options]"
    opts.on("--opa PATH", "OPA executable; defaults to opa on PATH") { |value| options[:opa] = value }
    opts.on("--repository-root PATH", "Repository root containing tools/rego/opa-version") do |value|
      options[:repository_root] = File.expand_path(value)
    end
  end

  begin
    parser.parse!
  rescue OptionParser::ParseError => e
    warn e.message
    warn parser
    exit 2
  end

  exit(IonRegoToolchain.validate(**options) ? 0 : 1)
end
