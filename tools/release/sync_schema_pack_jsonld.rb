#!/usr/bin/env ruby

require "date"
require "json"
require "optparse"
require "set"
require "yaml"

module IonSchemaPackJSONLD
  module_function

  def collect_properties(value, result = {})
    case value
    when Hash
      if value["properties"].is_a?(Hash)
        value["properties"].each do |name, schema|
          result[name] ||= schema.is_a?(Hash) ? schema["description"].to_s.strip : ""
        end
      end
      value.each_value { |child| collect_properties(child, result) }
    when Array
      value.each { |child| collect_properties(child, result) }
    end
    result
  end

  # The IRI a context term maps to: the string itself, or the @id of an
  # expanded term definition ({"@id": ..., "@context": ...}); ion:<name> when
  # the context does not define the term.
  def term_id(definition, name)
    return definition if definition.is_a?(String)
    return definition["@id"] if definition.is_a?(Hash) && definition["@id"].is_a?(String)

    "ion:#{name}"
  end

  # Terms defined in the scoped @context of an expanded term definition, for
  # example {"commission": {"@id": "ion:commission", "@context": {"type":
  # "ion:commissionType"}}}, mapped to the IRIs they take there. A property
  # defined only in such a scoped context gets no top-level term, so a generic
  # name such as type does not leak into the rest of the pack.
  def scoped_term_ids(context, result = {})
    context.each_value do |definition|
      next unless definition.is_a?(Hash) && definition["@context"].is_a?(Hash)

      definition["@context"].each do |term, scoped|
        next if term.start_with?("@")

        id = scoped.is_a?(Hash) ? scoped["@id"] : scoped
        next unless id.is_a?(String)

        (result[term] ||= []) << id unless result.fetch(term, []).include?(id)
      end
      scoped_term_ids(definition["@context"], result)
    end
    result
  end

  def synchronize(directory)
    attributes_path = File.join(directory, "attributes.yaml")
    context_path = File.join(directory, "context.jsonld")
    vocab_path = File.join(directory, "vocab.jsonld")
    attributes = YAML.safe_load(File.read(attributes_path), permitted_classes: [Date, Time], aliases: true)
    schemas = attributes.dig("components", "schemas") || {}
    properties = collect_properties(schemas)
    context_document = JSON.parse(File.read(context_path))
    vocab_document = JSON.parse(File.read(vocab_path))
    context = context_document.fetch("@context")

    context.keys.each do |term|
      definition = context[term]
      next unless definition.is_a?(String) && definition.start_with?("ion:")

      local_name = definition.delete_prefix("ion:")
      if term.match?(/\A[A-Z]/)
        context.delete(term) unless schemas.key?(term) && local_name == term
      elsif term.match?(/\A[a-z]/)
        context.delete(term) unless properties.key?(term) && local_name == term
      end
    end
    scoped_ids = scoped_term_ids(context)
    properties.each_key { |name| context[name] ||= "ion:#{name}" unless scoped_ids.key?(name) }
    schemas.each_key { |name| context[name] ||= "ion:#{name}" }

    property_ids = properties.each_key.to_h do |name|
      [name, context.key?(name) ? [term_id(context[name], name)] : scoped_ids.fetch(name)]
    end
    allowed_property_ids = property_ids.values.flatten.to_set
    schema_ids = schemas.each_key.to_h { |name| [name, term_id(context[name], name)] }

    graph = vocab_document.fetch("@graph")
    graph.reject! do |node|
      id = node["@id"].to_s
      types = Array(node["@type"])
      local_name = id.delete_prefix("ion:")
      (types.include?("rdf:Property") && id.start_with?("ion:") && !allowed_property_ids.include?(id)) ||
        ((types.include?("rdfs:Class") || types.include?("owl:Class")) && id.start_with?("ion:") &&
          (!schemas.key?(local_name) || schema_ids[local_name] != id))
    end
    published_property_ids = graph.each_with_object(Set.new) do |node, ids|
      ids << node["@id"].to_s if Array(node["@type"]).include?("rdf:Property")
    end.to_set
    properties.each do |name, description|
      property_ids.fetch(name).each do |property_id|
        next if published_property_ids.include?(property_id)

        published_property_ids << property_id
        graph << {
          "@id" => property_id,
          "@type" => "rdf:Property",
          "rdfs:label" => name,
          "rdfs:comment" => description.empty? ? "#{name} property." : description
        }
      end
    end
    published_class_ids = graph.each_with_object(Set.new) do |node, ids|
      types = Array(node["@type"])
      ids << node["@id"].to_s if types.include?("rdfs:Class") || types.include?("owl:Class")
    end
    schemas.each do |name, schema|
      class_id = schema_ids.fetch(name)
      next if published_class_ids.include?(class_id)

      graph << {
        "@id" => class_id,
        "@type" => "rdfs:Class",
        "rdfs:label" => schema["title"].to_s.empty? ? name : schema["title"],
        "rdfs:comment" => schema["description"].to_s.strip.empty? ? "#{name} class." : schema["description"].to_s.strip
      }
    end

    [
      [context_path, "#{JSON.pretty_generate(context_document)}\n"],
      [vocab_path, "#{JSON.pretty_generate(vocab_document)}\n"]
    ]
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    options = { apply: false }
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: ruby tools/release/sync_schema_pack_jsonld.rb [--apply] PACK_DIR..."
      opts.on("--apply", "Write synchronized JSON-LD files (default: dry-run)") { options[:apply] = true }
    end
    parser.parse!
    if ARGV.empty?
      warn parser
      exit 2
    end

    changed = []
    ARGV.each do |directory|
      IonSchemaPackJSONLD.synchronize(directory).each do |path, output|
        next if File.read(path) == output

        changed << path
        File.write(path, output) if options[:apply]
      end
    end
    puts "#{options[:apply] ? "updated" : "would update"}: #{changed.empty? ? "none" : changed.join(", ")}"
  rescue Errno::ENOENT, JSON::ParserError, Psych::SyntaxError, KeyError => e
    warn "JSON-LD synchronization failed: #{e.message}"
    exit 1
  end
end
