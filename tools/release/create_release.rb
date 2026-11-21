#!/usr/bin/env ruby

require "date"
require "fileutils"
require "optparse"
require "pathname"
require "tmpdir"
require "yaml"

module IonReleaseCreate
  RELEASE_NAME = /\Arelease([1-9][0-9]*)\z/

  module_function

  def create(source_root, target_root, write: false)
    source = Pathname.new(File.expand_path(source_root))
    target = Pathname.new(File.expand_path(target_root))
    source_manifest = load_manifest(source)
    source_number = release_number(source.basename.to_s)
    target_number = release_number(target.basename.to_s)

    raise ArgumentError, "source release directory does not exist: #{source}" unless source.directory?
    raise ArgumentError, "source manifest must be published" unless source_manifest["status"] == "published"
    raise ArgumentError, "target must be the next integer release" unless target_number == source_number + 1
    raise ArgumentError, "source and target must share a parent directory" unless source.parent == target.parent
    raise ArgumentError, "target release already exists: #{target}" if target.exist?

    file_count = Dir.glob(source.join("**/*").to_s, File::FNM_DOTMATCH).count { |path| File.file?(path) }
    return { "mode" => "dry-run", "source" => source.to_s, "target" => target.to_s, "files" => file_count } unless write

    temporary = Pathname.new(Dir.mktmpdir(".#{target.basename}-", target.parent.to_s))
    staged = temporary.join(target.basename)
    begin
      FileUtils.cp_r(source.to_s, staged.to_s)
      rewrite_tree(staged, source_number, target_number)
      reset_manifest(staged, load_manifest(staged), target_number)
      reset_release_documents(staged, target_number)
      FileUtils.mv(staged.to_s, target.to_s)
    ensure
      FileUtils.remove_entry(temporary.to_s) if temporary.exist?
    end

    { "mode" => "write", "source" => source.to_s, "target" => target.to_s, "files" => file_count }
  end

  def load_manifest(root)
    path = root.join("release.yaml")
    raise ArgumentError, "release manifest does not exist: #{path}" unless path.file?

    YAML.safe_load(path.read, permitted_classes: [Date, Time], aliases: true)
  rescue Psych::SyntaxError => e
    raise ArgumentError, "invalid release manifest: #{e.message.lines.first.strip}"
  end

  def release_number(name)
    match = RELEASE_NAME.match(name)
    raise ArgumentError, "release directory must be named releaseN: #{name}" unless match

    match[1].to_i
  end

  def rewrite_tree(root, source_number, target_number)
    source_name = "release#{source_number}"
    target_name = "release#{target_number}"
    source_label = "Release #{source_number}"
    target_label = "Release #{target_number}"

    Dir.glob(root.join("**/*").to_s, File::FNM_DOTMATCH).sort.each do |path_string|
      path = Pathname.new(path_string)
      next unless path.file?

      body = path.binread
      text = body.dup.force_encoding(Encoding::UTF_8)
      next unless text.valid_encoding? && !text.include?("\0")

      rewritten = text.gsub(source_name, target_name).gsub(source_label, target_label)
      path.binwrite(rewritten) if rewritten != text
    end
  end

  def reset_manifest(root, source_manifest, target_number)
    manifest = Marshal.load(Marshal.dump(source_manifest))
    manifest["release"] = target_number
    manifest["name"] = "release#{target_number}"
    manifest["status"] = "draft"
    manifest["publishedAt"] = nil
    manifest["publicBaseUrl"] = "https://schema.ion.id/release#{target_number}/"
    manifest["toolingCommit"] = nil
    manifest["artifactChecksums"] = {}
    manifest["notes"] = Array(manifest["notes"]).map do |note|
      if note.include?("Release URLs became permanent")
        "Draft Release #{target_number} URLs are unsupported until publication."
      else
        note
      end
    end
    logistics_notes = manifest.dig("implementationGuidance", "areas", "logistics", "notes")
    if logistics_notes.is_a?(Array)
      logistics_notes.map! do |note|
        note.match?(/expect refinements in Release \d+/) ?
          note.sub(/Release \d+/, "Release #{target_number + 1}") : note
      end
    end

    output = YAML.dump(manifest).sub(/\A---\n/, "")
    output = output.gsub(/^(publishedAt|toolingCommit):[ \t]*$/, '\\1: null')
    root.join("release.yaml").write(output)
  end

  def reset_release_documents(root, target_number)
    readme_path = root.join("README.md")
    readme = readme_path.read
    readme.sub!(/^> \*\*Status:.*$/, "> **Status: DRAFT — not assigned to a release channel.**")
    readme.sub!(
      /Release #{target_number} was published on .*?\nEvery file in this directory is now immutable\.\n/m,
      "Release #{target_number} is the active mutable draft. It is not assigned to a release channel, and its public URLs are unsupported until publication.\n"
    )
    readme.sub!(
      "Release #{target_number} is the first versioned bundle of the ION Network Specification.",
      "Release #{target_number} is the mutable successor to the published Release #{target_number - 1} baseline."
    )
    readme.sub!(
      /Run the publication gate to verify the immutable release and its channel\nassignment:/,
      "The publication form is expected to fail while the manifest remains a draft:"
    )
    readme_path.write(readme)

    notices_path = root.join("NOTICES.md")
    notices = notices_path.read
    notices.sub!(/^\*\*Status:\*\*.*$/, "**Status:** Draft Release #{target_number} baseline")
    notices.sub!(
      /^This notice records the dependency provenance of the published Release #{target_number} bundle\.$/,
      "This notice records dependency provenance for the mutable Release #{target_number} draft."
    )
    notices_path.write(notices)
  end
end

if $PROGRAM_NAME == __FILE__
  options = { write: false }
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby tools/release/create_release.rb [--write] SOURCE_RELEASE TARGET_RELEASE"
    opts.on("--write", "Create the target release; default is a dry run") { options[:write] = true }
  end

  begin
    parser.parse!
    source = ARGV.fetch(0)
    target = ARGV.fetch(1)
    result = IonReleaseCreate.create(source, target, write: options[:write])
    puts "#{result.fetch('mode')}: #{result.fetch('source')} -> #{result.fetch('target')} (#{result.fetch('files')} files)"
  rescue IndexError, OptionParser::ParseError, ArgumentError => e
    warn e.message
    warn parser
    exit 1
  end
end
