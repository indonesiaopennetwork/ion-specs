#!/usr/bin/env ruby

require "open3"
require "optparse"
require "pathname"
require "yaml"

module IonReleaseImmutability
  module_function

  def published_release_paths(releases_root)
    root = Pathname.new(File.expand_path(releases_root))
    Dir[root.join("release*/release.yaml").to_s].sort.each_with_object([]) do |manifest_path, result|
      manifest = YAML.safe_load(File.read(manifest_path), aliases: true)
      if manifest["status"] == "published"
        result << Pathname.new(manifest_path).dirname.relative_path_from(root.parent).to_s
      end
    end
  end

  def validate(published_paths, changed_paths)
    published_paths.flat_map do |release_path|
      changed_paths
        .select { |path| path == release_path || path.start_with?("#{release_path}/") }
        .map { |path| "published release is immutable: #{path}" }
    end.uniq.sort
  end
end

if $PROGRAM_NAME == __FILE__
  options = { against: nil }
  OptionParser.new do |parser|
    parser.on("--against REF", "Also compare the working tree with a Git ref") { |value| options[:against] = value }
  end.parse!(ARGV)
  releases_root = ARGV.fetch(0, "releases")
  repository_root = Pathname.new(File.expand_path("../..", __dir__))
  published = IonReleaseImmutability.published_release_paths(repository_root.join(releases_root))

  commands = [["git", "status", "--porcelain", "--untracked-files=all", "--", *published]]
  commands << ["git", "diff", "--name-only", options[:against], "--", *published] if options[:against] && !published.empty?
  changed = commands.flat_map do |command|
    next [] if published.empty?
    stdout, stderr, status = Open3.capture3(*command, chdir: repository_root.to_s)
    unless status.success?
      warn stderr
      exit 2
    end
    if command[1] == "status"
      stdout.lines.map { |line| line.sub(/\A.. /, "").strip }
    else
      stdout.lines.map(&:strip)
    end
  end.reject(&:empty?).uniq

  errors = IonReleaseImmutability.validate(published, changed)
  if errors.empty?
    comparison = options[:against] ? " and #{options[:against]}" : ""
    puts "published release immutability validation passed: working tree#{comparison}"
  else
    warn "published release immutability validation failed:"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
