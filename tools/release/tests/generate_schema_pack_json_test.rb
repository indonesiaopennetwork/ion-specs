#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../generate_schema_pack_json"

class GenerateSchemaPackJsonTest < Minitest::Test
  def test_generates_defs_and_rewrites_local_component_references
    Dir.mktmpdir do |directory|
      path = File.join(directory, "attributes.yaml")
      File.write(
        path,
        <<~YAML
          components:
            schemas:
              Child:
                type: object
              Root:
                type: object
                x-jsonld:
                  '@context': https://schema.ion.id/release1/example/v1/context.jsonld
                properties:
                  child:
                    $ref: '#/components/schemas/Child'
        YAML
      )

      result = IonSchemaPackJSON.generate(path, "Root")

      assert_equal "https://schema.ion.id/release1/example/v1", result.fetch("$id")
      assert_equal "#/$defs/Root", result.fetch("$ref")
      assert_equal "#/$defs/Child", result.dig("$defs", "Root", "properties", "child", "$ref")
    end
  end
end
