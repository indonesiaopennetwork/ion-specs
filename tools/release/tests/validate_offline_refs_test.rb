require "minitest/autorun"
require "tmpdir"

require_relative "../validate_offline_refs"

class ValidateOfflineRefsTest < Minitest::Test
  def test_resolves_object_and_array_json_pointers
    document = { "components" => { "schemas" => [{ "a/b" => true }] } }
    assert_equal true, IonOfflineRefs.resolve_pointer(document, "/components/schemas/0/a~1b")
  end

  def test_validates_release_public_and_local_references
    Dir.mktmpdir("release9") do |parent|
      release_root = File.join(parent, "release9")
      Dir.mkdir(release_root)
      File.write(File.join(release_root, "target.yaml"), "components:\n  schemas:\n    Thing:\n      type: string\n")
      File.write(
        File.join(release_root, "source.yaml"),
        "one:\n  $ref: target.yaml#/components/schemas/Thing\ntwo:\n  $ref: https://schema.ion.id/release9/target.yaml#/components/schemas/Thing\n"
      )

      validator = IonOfflineRefs::Validator.new(release_root)
      assert validator.validate, validator.errors.join("\n")
      assert_equal 2, validator.reference_count
    end
  end

  def test_rejects_external_and_missing_pointer_references
    Dir.mktmpdir("release7") do |parent|
      release_root = File.join(parent, "release7")
      Dir.mkdir(release_root)
      File.write(File.join(release_root, "source.yaml"), "one:\n  $ref: https://example.com/a.yaml#/x\ntwo:\n  $ref: '#/missing'\n")

      validator = IonOfflineRefs::Validator.new(release_root)
      refute validator.validate
      assert_equal 2, validator.errors.length
    end
  end
end
