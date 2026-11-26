#!/usr/bin/env ruby

require "optparse"
require_relative "check_toolchain"
require_relative "lib/bundle"

options = { opa: "opa", write: false, test_sign: false }
parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/rego/build_bundle.rb [options] RELEASE_ROOT"
  opts.on("--opa PATH", "OPA executable; defaults to opa on PATH") { |value| options[:opa] = value }
  opts.on("--write", "Atomically replace the canonical bundle after verification") { options[:write] = true }
  opts.on("--test-sign", "Use a generated ephemeral TEST-ONLY ES256 key") { options[:test_sign] = true }
  opts.on("--signing-key PATH", "External private signing key; never copied") { |value| options[:signing_key] = value }
  opts.on("--verification-key PATH", "Public key matching --signing-key") { |value| options[:verification_key] = value }
end

begin
  parser.parse!
  release_root = ARGV.fetch(0)
  external = options[:signing_key] || options[:verification_key]
  if options[:test_sign] && external
    raise OptionParser::InvalidOption, "--test-sign cannot be combined with external keys"
  end
  if !options[:test_sign] && (!options[:signing_key] || !options[:verification_key])
    raise OptionParser::MissingArgument, "choose --test-sign or provide both --signing-key and --verification-key"
  end
rescue IndexError, OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 2
end

repository_root = File.expand_path("../..", __dir__)
exit 1 unless IonRegoToolchain.validate(repository_root: repository_root, opa: options[:opa])
mode = options[:test_sign] ? :test : :external
success = IonRegoBundle.build(
  release_root,
  opa: options[:opa],
  signing_mode: mode,
  signing_key: options[:signing_key],
  verification_key: options[:verification_key],
  write: options[:write]
)
exit(success ? 0 : 1)
