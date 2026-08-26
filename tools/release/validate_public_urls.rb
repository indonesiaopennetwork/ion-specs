#!/usr/bin/env ruby

require "find"
require "pathname"
require "yaml"

module IonReleasePublicUrls
  TEXT_EXTENSIONS = %w[.json .jsonld .md .yaml .yml].freeze
  URL_PATTERN = %r{https://schema\.ion\.id/release[1-9][0-9]*/[^\s"'`<>\)\}\]]*}.freeze
  LEGACY_URL_PATTERN = %r{https://schema\.ion\.id/releases/release[1-9][0-9]*/[^\s"'`<>\)\}\]]*}.freeze

  module_function

  def validate(release_root, manifest = nil)
    root = Pathname.new(File.expand_path(release_root))
    manifest ||= YAML.safe_load(File.read(root.join("release.yaml")), aliases: true)
    base = manifest.fetch("publicBaseUrl")
    errors = []

    text_files(root).each do |path|
      next unless File.file?(path) && TEXT_EXTENSIONS.include?(File.extname(path))

      File.read(path).scan(LEGACY_URL_PATTERN).each do |url|
        clean_url = url.sub(/[.,;:]\z/, "")
        errors << "#{Pathname.new(path).relative_path_from(root)}: legacy public URL namespace: #{clean_url}"
      end

      File.read(path).scan(URL_PATTERN).each do |url|
        clean_url = url.sub(/[.,;:]\z/, "")
        unless clean_url.start_with?(base)
          errors << "#{Pathname.new(path).relative_path_from(root)}: public URL falls outside #{base}: #{clean_url}"
          next
        end
        relative_path = clean_url.delete_prefix(base).split("#", 2).first.to_s
        relative_path = "." if relative_path.empty?
        target = root.join(relative_path).cleanpath
        errors << "#{Pathname.new(path).relative_path_from(root)}: public URL target does not exist: #{clean_url}" unless target.exist?
      end
    end

    errors.uniq
  rescue Psych::SyntaxError => e
    ["invalid release manifest: #{e.message.lines.first.strip}"]
  end

  def text_files(root)
    paths = []
    Find.find(root.to_s) { |path| paths << path if File.file?(path) }
    paths.sort
  end
end

if $PROGRAM_NAME == __FILE__
  release_root = ARGV.fetch(0, "releases/release1")
  errors = IonReleasePublicUrls.validate(release_root)
  if errors.empty?
    puts "release public URL validation passed: #{release_root}"
  else
    warn "release public URL validation failed with #{errors.length} error(s):"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
