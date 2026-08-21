#!/usr/bin/env ruby

require "open3"
require "pathname"

publication = ARGV.delete("--publication")
release_root = Pathname.new(File.expand_path(ARGV.fetch(0, "releases/release1")))
repository_root = Pathname.new(File.expand_path("../..", __dir__))
release_name = release_root.basename.to_s

unless release_root.directory?
  warn "release directory does not exist: #{release_root}"
  exit 2
end

commands = [
  ["Release tool tests", ["ruby", "-Itools/release/tests", "-e", 'Dir["tools/release/tests/*_test.rb"].sort.each { |file| require File.expand_path(file) }']],
  ["Published release immutability", ["ruby", "tools/release/validate_release_immutability.rb", "releases"]],
  ["Manifest", ["ruby", "tools/release/validate_manifest.rb", release_root.join("release.yaml").to_s]],
  ["Release scope", ["ruby", "tools/release/validate_release_scope.rb", release_root.to_s]],
  ["Generated registries", ["ruby", "tools/release/generate_release_registries.rb", release_root.to_s]],
  ["Recorded artifact inventory", ["ruby", "tools/release/record_artifact_checksums.rb", release_root.to_s]],
  ["Artifact checksums", ["ruby", "tools/release/validate_artifact_checksums.rb", release_root.to_s]],
  ["Public release URLs", ["ruby", "tools/release/validate_public_urls.rb", release_root.to_s]],
  ["Offline references", ["ruby", "tools/release/validate_offline_refs.rb", release_root.to_s]]
]

if ENV["ION_IMMUTABILITY_BASE"] && !ENV["ION_IMMUTABILITY_BASE"].empty?
  commands[1][1].insert(2, "--against", ENV["ION_IMMUTABILITY_BASE"])
end

path_map = repository_root.join("tools/release/#{release_name}-path-map.json")
commands.insert(2, ["Release path map", ["ruby", "tools/release/validate_path_map.rb", "--require-targets", path_map.to_s]]) if path_map.file?
commands << ["Trade connections", ["ruby", "tools/release/validate_trade_connections.rb", release_root.to_s]]
if publication
  commands << ["Publication manifest gate", ["ruby", "tools/release/validate_manifest.rb", "--require-published", release_root.join("release.yaml").to_s]]
end

failed = []
commands.each do |label, command|
  puts "\n== #{label} =="
  stdout, stderr, status = Open3.capture3(*command, chdir: repository_root.to_s)
  print stdout
  warn stderr unless stderr.empty?
  failed << label unless status.success?
end

if failed.empty?
  puts "\nRelease validation passed: #{release_root}"
else
  warn "\nRelease validation failed: #{failed.join(', ')}"
  exit 1
end
