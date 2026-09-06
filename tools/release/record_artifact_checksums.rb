#!/usr/bin/env ruby

require "date"
require "digest"
require "optparse"
require "pathname"
require "yaml"

require_relative "validate_artifact_checksums"

options = { write: false }
OptionParser.new do |parser|
  parser.on("--write", "Write the complete release artifact inventory") { options[:write] = true }
end.parse!(ARGV)

release_root = Pathname.new(File.expand_path(ARGV.fetch(0, "releases/release1")))
manifest_path = release_root.join("release.yaml")
unless manifest_path.file?
  warn "release manifest does not exist: #{manifest_path}"
  exit 2
end

manifest = YAML.safe_load(File.read(manifest_path), permitted_classes: [Date, Time], aliases: true)
checksums = IonArtifactChecksums.artifact_files(release_root).to_h do |relative_path|
  [relative_path, Digest::SHA256.file(release_root.join(relative_path)).hexdigest]
end

if options[:write]
  manifest.fetch("dependencies", []).each do |dependency|
    dependency["releasedSha256"] = checksums.fetch(dependency.fetch("vendoredPath"))
  end
  manifest["artifactChecksums"] = checksums
  output = YAML.dump(manifest).sub(/\A---\n/, "")
  output = output.gsub(/^(publishedAt|toolingCommit):[ \t]*$/, '\\1: null')
  File.write(manifest_path, output)
  puts "recorded #{checksums.length} release artifact checksums: #{manifest_path}"
elsif manifest["artifactChecksums"] == checksums
  puts "release artifact checksums are current: #{checksums.length} files"
else
  warn "release artifact checksums are stale; run with --write after reviewing release changes"
  exit 1
end
