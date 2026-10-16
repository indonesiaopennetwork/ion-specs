#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "pathname"
require "uri"
require "yaml"

module IonSchemaValidatorStage
  module_function

  def stage(release_root, output_root)
    release_root = Pathname.new(File.expand_path(release_root))
    output_root = Pathname.new(File.expand_path(output_root))
    manifest_path = release_root.join("release.yaml")
    schema_root = release_root.join("schema")

    raise "release manifest does not exist: #{manifest_path}" unless manifest_path.file?
    raise "release schema directory does not exist: #{schema_root}" unless schema_root.directory?
    raise "output path already exists: #{output_root}" if output_root.exist?

    manifest = YAML.safe_load(
      File.read(manifest_path),
      permitted_classes: [Date, Time],
      aliases: true
    )
    public_base_url = manifest.fetch("publicBaseUrl")
    public_base_url += "/" unless public_base_url.end_with?("/")

    FileUtils.mkdir_p(output_root)
    FileUtils.cp_r(schema_root, output_root.join("schema"))

    rewritten = 0
    staged_schema_root = output_root.join("schema")
    document_paths = Dir.glob(staged_schema_root.join("**/{attributes.yaml,schema.json}"))
    document_paths.sort.each do |path|
      document = load_document(path)
      changes = rewrite_references!(document, public_base_url, output_root)
      write_document(path, document) unless changes.zero?
      rewritten += changes
    end

    build_type_index(document_paths, output_root)

    rewritten
  end

  def build_type_index(document_paths, output_root)
    index_root = output_root.join("extended-schemas")
    document_paths.grep(/attributes\.yaml\z/).each do |path|
      document = load_document(path)
      schemas = document.fetch("components", {}).fetch("schemas", {})
      schemas.each_value do |schema|
        type_name = schema.is_a?(Hash) && schema.dig("x-jsonld", "@type")
        next unless type_name.is_a?(String)

        local_name = type_name.split(":").last
        next if local_name.nil? || local_name.empty? || local_name.match?(/[\\\/]/)

        destination = index_root.join(local_name, "attributes.yaml")
        if destination.exist? && File.read(destination) != File.read(path)
          raise "duplicate staged schema type: #{type_name}"
        end
        FileUtils.mkdir_p(destination.dirname)
        FileUtils.cp(path, destination)
      end
    end
  end

  def load_document(path)
    if File.extname(path) == ".json"
      JSON.parse(File.read(path))
    else
      YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
    end
  end

  def write_document(path, document)
    if File.extname(path) == ".json"
      File.write(path, JSON.pretty_generate(document) + "\n")
    else
      File.write(path, YAML.dump(document).sub(/\A---\n/, ""))
    end
  end

  def rewrite_references!(value, public_base_url, output_root)
    case value
    when Hash
      value.sum do |key, child|
        if key == "$ref" && child.is_a?(String) && child.start_with?(public_base_url)
          value[key] = local_reference(child, public_base_url, output_root)
          1
        else
          rewrite_references!(child, public_base_url, output_root)
        end
      end
    when Array
      value.sum { |child| rewrite_references!(child, public_base_url, output_root) }
    else
      0
    end
  end

  def local_reference(reference, public_base_url, output_root)
    relative, fragment = reference.delete_prefix(public_base_url).split("#", 2)
    target = output_root.join(relative).cleanpath
    output_prefix = output_root.to_s + File::SEPARATOR
    unless target.to_s.start_with?(output_prefix) && target.file?
      raise "public $ref does not map to a staged file: #{reference}"
    end

    uri = URI::Generic.build(scheme: "file", path: target.to_s)
    fragment ? "#{uri}##{fragment}" : uri.to_s
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length != 2
    warn "usage: ruby tools/release/stage_schema_validator_tree.rb RELEASE_ROOT OUTPUT_ROOT"
    exit 2
  end

  begin
    count = IonSchemaValidatorStage.stage(ARGV[0], ARGV[1])
    puts "staged schema validator tree with #{count} local $ref rewrite(s): #{File.expand_path(ARGV[1])}"
    puts "extended schema index: #{File.expand_path(File.join(ARGV[1], "extended-schemas"))}"
  rescue StandardError => e
    warn e.message
    exit 2
  end
end
