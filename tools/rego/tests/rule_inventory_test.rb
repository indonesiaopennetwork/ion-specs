#!/usr/bin/env ruby

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/rule_inventory"
require_relative "registry_test_support"

class RuleInventoryTest < Minitest::Test
  include RegoRegistryTestSupport

  def test_valid_inventory_resolves_metadata_and_references
    Dir.mktmpdir do |root|
      release = build_repository(root)
      inventory, errors = IonRegoInventory.build(release)

      assert_empty errors
      assert_equal 1, inventory.fetch("rules").length
      assert_equal "ION-R2-TRD-0001", inventory.fetch("rules").first.fetch("id")
      assert_equal "ion.release2.trade.order", inventory.fetch("rules").first.fetch("package")
    end
  end

  def test_malformed_metadata_has_precise_diagnostic
    Dir.mktmpdir do |root|
      metadata = valid_metadata.sub("#   actions: [confirm]", "#   actions: [confirm")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata))

      assert errors.any? { |error| error.include?("malformed metadata") }
    end
  end

  def test_duplicate_rule_ids_are_rejected
    Dir.mktmpdir do |root|
      release = build_repository(root)
      source = File.join(release, "rules/rego/ion/release2/trade/order.rego")
      duplicate = File.join(release, "rules/rego/ion/release2/trade/duplicate.rego")
      write(duplicate, File.read(source).sub("package ion.release2.trade.order", "package ion.release2.trade.duplicate"))
      _inventory, errors = IonRegoInventory.build(release)

      assert errors.any? { |error| error.include?("duplicate rule ID ION-R2-TRD-0001") }
    end
  end

  def test_unresolved_reference_is_rejected
    Dir.mktmpdir do |root|
      metadata = valid_metadata(schema_path: "schema/extension/trade/Missing/v1/attributes.yaml")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata))

      assert_includes errors, "ION-R2-TRD-0001: unresolved release path schema/extension/trade/Missing/v1/attributes.yaml"
    end
  end

  def test_unsafe_reference_is_rejected
    Dir.mktmpdir do |root|
      metadata = valid_metadata(schema_path: "../release1/release.yaml")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata))

      assert errors.any? { |error| error.include?("unsafe or misclassified release path") }
    end
  end

  def test_rule_requires_semantic_test_reference
    Dir.mktmpdir do |root|
      release = build_repository(root, test_rule_id: "some other rule")
      _inventory, errors = IonRegoInventory.build(release)

      assert errors.any? { |error| error.include?("ION-R2-TRD-0001: no semantic test references") }
    end
  end

  def test_package_must_match_source_path
    Dir.mktmpdir do |root|
      release = build_repository(root, package_name: "ion.release2.trade.wrong")
      _inventory, errors = IonRegoInventory.build(release)

      assert_includes errors, "rules/rego/ion/release2/trade/order.rego: package must be ion.release2.trade.order, got ion.release2.trade.wrong"
    end
  end

  def test_action_and_protocol_error_code_must_resolve
    Dir.mktmpdir do |root|
      metadata = valid_metadata
        .sub("actions: [confirm]", "actions: [invented_action]")
        .sub("error_code: POL_ELIGIBILITY_NOT_MET", "error_code: POL_NOT_IN_PROTOCOL")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata))

      assert_includes errors, "ION-R2-TRD-0001: unknown action invented_action"
      assert_includes errors, "ION-R2-TRD-0001: unresolved protocol error code POL_NOT_IN_PROTOCOL"
    end
  end

  def test_policy_iri_must_resolve
    Dir.mktmpdir do |root|
      metadata = valid_metadata.sub("cancel.test.standard", "cancel.missing.standard")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata))

      assert_includes errors, "ION-R2-TRD-0001: unresolved policy IRI ion://policy/cancel.missing.standard"
    end
  end

  def test_data_config_access_must_be_declared
    Dir.mktmpdir do |root|
      release = build_repository(root)
      source = File.join(release, "rules/rego/ion/release2/trade/order.rego")
      File.open(source, "a") { |file| file.write("\nconfigured_limit := data.config.order.limit\n") }
      _inventory, errors = IonRegoInventory.build(release)

      assert_includes errors, "rules/rego/ion/release2/trade/order.rego: data.config.order.limit is not declared in rule metadata"
    end
  end

  def test_rule_id_must_match_release_and_sector
    Dir.mktmpdir do |root|
      metadata = valid_metadata(id: "ION-R3-LOG-0001")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata, test_rule_id: "ION-R3-LOG-0001"))

      assert errors.any? { |error| error.include?("expected ION-R2-(COM|TRD|LOG|HSP)-NNNN") }
      assert errors.any? { |error| error.include?("rule ID area LOG does not match sector trade") }
    end
  end

  def test_violation_rule_requires_metadata
    Dir.mktmpdir do |root|
      metadata = valid_metadata.sub("# METADATA", "# missing metadata marker")
      _inventory, errors = IonRegoInventory.build(build_repository(root, metadata: metadata))

      assert errors.any? { |error| error.include?("violation rule must have immediately preceding METADATA") }
    end
  end

  def test_release_reference_must_not_traverse_symlink
    Dir.mktmpdir do |root|
      release = build_repository(root)
      real = File.join(release, "schema/extension/trade/TradeOffer/v1/attributes.yaml")
      File.delete(real)
      File.symlink(File.join(release, "release.yaml"), real)
      _inventory, errors = IonRegoInventory.build(release)

      assert errors.any? { |error| error.include?("release path must not traverse a symlink") }
    end
  end
end
