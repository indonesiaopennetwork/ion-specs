#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "../stage_schema_validator_tree"

class StageSchemaValidatorTreeTest < Minitest::Test
  def test_stages_schema_and_rewrites_release_refs_without_changing_source
    Dir.mktmpdir do |directory|
      release_root = File.join(directory, "release1")
      output_root = File.join(directory, "staged")
      target = File.join(release_root, "schema/common/Thing/attributes.yaml")
      source = File.join(release_root, "schema/extension/Widget/attributes.yaml")
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.mkdir_p(File.dirname(source))
      File.write(
        File.join(release_root, "release.yaml"),
        "publicBaseUrl: https://schema.ion.id/release1/\n"
      )
      File.write(target, <<~YAML)
        openapi: 3.1.0
        components:
          schemas:
            Thing:
              type: object
              x-jsonld:
                '@type': ion:Thing
      YAML
      original = <<~YAML
        openapi: 3.1.0
        components:
          schemas:
            Widget:
              $ref: https://schema.ion.id/release1/schema/common/Thing/attributes.yaml#/components/schemas/Thing
              x-jsonld:
                '@type': ion:Widget
      YAML
      File.write(source, original)

      assert_equal 1, IonSchemaValidatorStage.stage(release_root, output_root)

      staged = YAML.safe_load(
        File.read(File.join(output_root, "schema/extension/Widget/attributes.yaml"))
      )
      reference = staged.fetch("components").fetch("schemas").fetch("Widget").fetch("$ref")
      assert_equal(
        "file://#{output_root}/schema/common/Thing/attributes.yaml#/components/schemas/Thing",
        reference
      )
      assert_equal original, File.read(source)
      assert File.file?(File.join(output_root, "extended-schemas/Thing/attributes.yaml"))
      assert File.file?(File.join(output_root, "extended-schemas/Widget/attributes.yaml"))
    end
  end

  def test_rejects_an_existing_output_path
    Dir.mktmpdir do |directory|
      release_root = File.join(directory, "release1")
      output_root = File.join(directory, "staged")
      FileUtils.mkdir_p(File.join(release_root, "schema"))
      FileUtils.mkdir_p(output_root)
      File.write(
        File.join(release_root, "release.yaml"),
        "publicBaseUrl: https://schema.ion.id/release1/\n"
      )

      error = assert_raises(RuntimeError) do
        IonSchemaValidatorStage.stage(release_root, output_root)
      end
      assert_includes error.message, "output path already exists"
    end
  end
end
