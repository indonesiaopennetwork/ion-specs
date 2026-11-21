#!/usr/bin/env ruby

require "open3"
require "optparse"
require "pathname"
require "yaml"

module IonReleaseImmutability
  module_function

  def published_release_paths(releases_root)
    published_paths(release_statuses(releases_root))
  end

  def release_statuses(releases_root)
    root = Pathname.new(File.expand_path(releases_root))
    manifest_paths(root).each_with_object({}) do |manifest_path, result|
      manifest = YAML.safe_load(File.read(manifest_path), aliases: true)
      release_path = Pathname.new(manifest_path).dirname.relative_path_from(root.parent).to_s
      result[release_path] = manifest["status"]
    end
  end

  def release_statuses_at_ref(repository_root, releases_root, ref)
    releases_path = Pathname.new(File.expand_path(releases_root)).relative_path_from(Pathname.new(repository_root)).to_s
    stdout, stderr, status = Open3.capture3(
      "git", "ls-tree", "-r", "--name-only", ref, "--", releases_path,
      chdir: repository_root
    )
    raise ArgumentError, stderr.strip unless status.success?

    stdout.lines.map(&:strip).grep(%r{\A#{Regexp.escape(releases_path)}/release[1-9][0-9]*/release\.yaml\z}).to_h do |manifest_path|
      body, show_error, show_status = Open3.capture3("git", "show", "#{ref}:#{manifest_path}", chdir: repository_root)
      raise ArgumentError, show_error.strip unless show_status.success?
      manifest = YAML.safe_load(body, aliases: true)
      [File.dirname(manifest_path), manifest["status"]]
    end
  end

  def published_paths(statuses)
    statuses.select { |_, status| status == "published" }.keys.sort
  end

  def validate_transitions(base_statuses, current_statuses)
    current_statuses.each_with_object([]) do |(release_path, status), errors|
      next unless status == "published"
      next if %w[draft published].include?(base_statuses[release_path])

      errors << "published release must transition from an existing draft: #{release_path}"
    end
  end

  def manifest_paths(root)
    return [] unless root.directory?

    root.children
      .select { |path| path.directory? && path.basename.to_s.match?(/\Arelease[1-9][0-9]*\z/) }
      .map { |path| path.join("release.yaml") }
      .select(&:file?)
      .map(&:to_s)
      .sort
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
  releases_path = repository_root.join(releases_root)
  baseline_ref = options[:against] || "HEAD"

  begin
    current_statuses = IonReleaseImmutability.release_statuses(releases_path)
    baseline_statuses = IonReleaseImmutability.release_statuses_at_ref(
      repository_root.to_s,
      releases_path.to_s,
      baseline_ref
    )
  rescue ArgumentError, Psych::SyntaxError => e
    warn "published release immutability validation failed: #{e.message}"
    exit 2
  end

  published = IonReleaseImmutability.published_paths(baseline_statuses)

  commands = [["git", "status", "--porcelain", "--untracked-files=all", "--", *published]]
  commands << ["git", "diff", "--name-only", baseline_ref, "--", *published] if !published.empty?
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
  errors.concat(IonReleaseImmutability.validate_transitions(baseline_statuses, current_statuses))
  if errors.empty?
    puts "published release immutability validation passed against #{baseline_ref}"
  else
    warn "published release immutability validation failed:"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
