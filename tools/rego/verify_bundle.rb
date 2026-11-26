#!/usr/bin/env ruby

require "optparse"
require_relative "check_toolchain"
require_relative "lib/bundle"

options = { opa: "opa" }
parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/rego/verify_bundle.rb [options] RELEASE_ROOT"
  opts.on("--opa PATH", "OPA executable; defaults to opa on PATH") { |value| options[:opa] = value }
  opts.on("--bundle PATH", "Bundle path; defaults to the canonical release bundle") { |value| options[:bundle] = value }
  opts.on("--public-key PATH", "Verification key; defaults to the committed TEST-ONLY public key") { |value| options[:public_key] = value }
end

begin
  parser.parse!
  release_root = ARGV.fetch(0)
rescue IndexError, OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 2
end

repository_root = File.expand_path("../..", __dir__)
exit 1 unless IonRegoToolchain.validate(repository_root: repository_root, opa: options[:opa])
paths = IonRegoBundle.canonical_paths(release_root)
bundle = options[:bundle] || paths.fetch(:bundle)
public_key = options[:public_key] || paths.fetch(:test_public_key)
errors = IonRegoBundle.verify(release_root, bundle, opa: options[:opa], public_key: public_key)
unless errors.empty?
  errors.each { |message| warn "ERROR: #{message}" }
  exit 1
end
puts "verified signed OPA bundle: #{bundle}"
