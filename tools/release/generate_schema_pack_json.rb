#!/usr/bin/env ruby

require "json"
require "optparse"
require "yaml"

module IonSchemaPackJSON
  module_function

  def transform(value)
    case value
    when Hash
      value.to_h do |key, child|
        transformed = if key == "$ref" && child.is_a?(String)
                        child.sub(%r{\A#/components/schemas/}, "#/$defs/")
                      else
                        transform(child)
                      end
        [key, transformed]
      end
    when Array
      value.map { |child| transform(child) }
    else
      value
    end
  end

  def generate(attributes_path, root_schema)
    document = YAML.safe_load_file(attributes_path, aliases: true)
    schemas = document.dig("components", "schemas") || {}
    raise KeyError, "root schema #{root_schema.inspect} not found" unless schemas.key?(root_schema)

    context_url = schemas.dig(root_schema, "x-jsonld", "@context")
    raise KeyError, "root schema #{root_schema.inspect} has no x-jsonld @context" unless context_url

    {
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "$id" => context_url.sub(%r{/context\.jsonld\z}, ""),
      "$ref" => "#/$defs/#{root_schema}",
      "$defs" => transform(schemas)
    }
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    options = { write: false }
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: ruby tools/release/generate_schema_pack_json.rb [--write] PACK_DIR ROOT_SCHEMA"
      opts.on("--write", "Write schema.json (default: print generated JSON)") { options[:write] = true }
    end
    parser.parse!
    raise OptionParser::MissingArgument, parser.banner unless ARGV.length == 2

    directory, root_schema = ARGV
    output = "#{JSON.pretty_generate(IonSchemaPackJSON.generate(File.join(directory, "attributes.yaml"), root_schema))}\n"
    if options[:write]
      File.write(File.join(directory, "schema.json"), output)
      puts "wrote: #{File.join(directory, "schema.json")}"
    else
      puts output
    end
  rescue Errno::ENOENT, JSON::ParserError, Psych::SyntaxError, KeyError, OptionParser::ParseError => e
    warn "schema-pack JSON generation failed: #{e.message}"
    exit 1
  end
end
