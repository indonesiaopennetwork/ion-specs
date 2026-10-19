#!/usr/bin/env ruby

require "fileutils"
require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../sync_schema_pack_jsonld"

class SyncSchemaPackJsonldTest < Minitest::Test
  def test_preserves_external_property_iri_without_adding_ion_duplicate
    Dir.mktmpdir do |directory|
      File.write(
        File.join(directory, "attributes.yaml"),
        <<~YAML
          components:
            schemas:
              IdentifiableLocation:
                type: object
                properties:
                  id:
                    type: string
                  geo:
                    type: object
        YAML
      )
      File.write(
        File.join(directory, "context.jsonld"),
        JSON.pretty_generate(
          "@context" => {
            "ion" => "https://schema.ion.id/example#",
            "beckn" => "https://spec.beckn.io/vocab/v2.0.0#",
            "id" => "ion:id",
            "geo" => "beckn:geo",
            "IdentifiableLocation" => "ion:IdentifiableLocation"
          }
        )
      )
      File.write(
        File.join(directory, "vocab.jsonld"),
        JSON.pretty_generate(
          "@graph" => [
            { "@id" => "ion:id", "@type" => "rdf:Property" },
            { "@id" => "beckn:geo", "@type" => "rdf:Property" },
            { "@id" => "ion:geo", "@type" => "rdf:Property" }
          ]
        )
      )

      outputs = IonSchemaPackJSONLD.synchronize(directory).to_h
      graph = JSON.parse(outputs.fetch(File.join(directory, "vocab.jsonld"))).fetch("@graph")
      property_ids = graph.each_with_object([]) do |node, result|
        result << node["@id"] if Array(node["@type"]).include?("rdf:Property") && node["@id"]
      end

      assert_includes property_ids, "beckn:geo"
      refute_includes property_ids, "ion:geo"
      assert_includes property_ids, "ion:id"
      assert graph.any? { |node| node["@id"] == "ion:IdentifiableLocation" && node["@type"] == "rdfs:Class" }
    end
  end

  def test_uses_the_id_of_an_expanded_term_definition
    Dir.mktmpdir do |directory|
      File.write(
        File.join(directory, "attributes.yaml"),
        <<~YAML
          components:
            schemas:
              Example:
                type: object
                properties:
                  policies:
                    type: object
                    properties:
                      policyRef:
                        type: string
        YAML
      )
      File.write(
        File.join(directory, "context.jsonld"),
        JSON.pretty_generate(
          "@context" => {
            "ion" => "https://schema.ion.id/example#",
            "rcoa" => "https://schema.beckn.io/RetailOffer#",
            "policies" => { "@id" => "rcoa:policies", "@context" => { "policyRef" => "rcoa:policyRef" } },
            "policyRef" => "rcoa:policyRef",
            "Example" => "ion:Example"
          }
        )
      )
      File.write(
        File.join(directory, "vocab.jsonld"),
        JSON.pretty_generate(
          "@graph" => [
            { "@id" => "rcoa:policies", "@type" => "rdf:Property" },
            { "@id" => "rcoa:policyRef", "@type" => "rdf:Property" },
            { "@id" => "ion:policies", "@type" => "rdf:Property" }
          ]
        )
      )

      outputs = IonSchemaPackJSONLD.synchronize(directory).to_h
      graph = JSON.parse(outputs.fetch(File.join(directory, "vocab.jsonld"))).fetch("@graph")
      context = JSON.parse(outputs.fetch(File.join(directory, "context.jsonld"))).fetch("@context")
      ids = graph.map { |node| node["@id"] }

      assert_includes ids, "rcoa:policies"
      refute_includes ids, "ion:policies"
      assert_equal "rcoa:policies", context["policies"]["@id"]
    end
  end
end
