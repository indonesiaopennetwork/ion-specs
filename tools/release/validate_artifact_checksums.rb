#!/usr/bin/env ruby

require "digest"
require "find"
require "pathname"
require "yaml"

module IonArtifactChecksums
  ARTIFACT_ROOTS = %w[schema flows policies errors].freeze

  module_function

  def artifact_files(root)
    ARTIFACT_ROOTS.flat_map do |directory|
      base = root.join(directory)
      next [] unless base.directory?

      files = []
      Find.find(base.to_s) { |path| files << path if File.file?(path) }
      files
    end.sort.map { |path| Pathname.new(path).relative_path_from(root).to_s }
  end

  def validate(release_root, manifest = nil)
    root = Pathname.new(File.expand_path(release_root))
    manifest ||= YAML.safe_load(File.read(root.join("release.yaml")), aliases: true)
    errors = []
    checksums = manifest.fetch("artifactChecksums", {})

    checksums.each do |relative_path, expected|
      path = contained_path(root, relative_path, errors)
      next unless path
      unless path.file?
        errors << "artifact checksum target does not exist: #{relative_path}"
        next
      end
      actual = Digest::SHA256.file(path).hexdigest
      errors << "artifact checksum mismatch: #{relative_path}" unless actual == expected
    end

    release_files = artifact_files(root)
    missing_checksums = release_files - checksums.keys
    missing_checksums.each { |path| errors << "release artifact is not checksummed: #{path}" }
    recorded_release_files = checksums.keys.select { |path| ARTIFACT_ROOTS.include?(path.split("/", 2).first) }
    (recorded_release_files - release_files).each do |path|
      errors << "checksum records missing release artifact: #{path}"
    end

    manifest.fetch("dependencies", []).each do |dependency|
      relative_path = dependency["vendoredPath"]
      path = contained_path(root, relative_path, errors)
      next unless path&.file?
      actual = Digest::SHA256.file(path).hexdigest
      unless actual == dependency["releasedSha256"]
        errors << "dependency released checksum mismatch: #{dependency['name']}"
      end
      unless checksums[relative_path] == dependency["releasedSha256"]
        errors << "dependency and artifact checksum disagree: #{dependency['name']}"
      end
    end

    errors
  rescue Psych::SyntaxError => e
    ["invalid release manifest: #{e.message.lines.first.strip}"]
  end

  def contained_path(root, relative_path, errors)
    unless relative_path.is_a?(String) && !relative_path.empty?
      errors << "invalid artifact path: #{relative_path.inspect}"
      return nil
    end
    path = root.join(relative_path).cleanpath
    prefix = "#{root}#{File::SEPARATOR}"
    unless path.to_s.start_with?(prefix)
      errors << "artifact path escapes release: #{relative_path}"
      return nil
    end
    path
  end
end

if $PROGRAM_NAME == __FILE__
  release_root = ARGV.fetch(0, "releases/release1")
  errors = IonArtifactChecksums.validate(release_root)
  if errors.empty?
    puts "artifact checksum validation passed: #{release_root}"
  else
    warn "artifact checksum validation failed with #{errors.length} error(s):"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
