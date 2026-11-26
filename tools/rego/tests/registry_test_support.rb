require "fileutils"
require "json"

module RegoRegistryTestSupport
  def build_repository(root, metadata: valid_metadata, package_name: "ion.release2.trade.order", test_rule_id: "ION-R2-TRD-0001")
    release = File.join(root, "releases", "release2")
    write(File.join(release, "release.yaml"), "schemaVersion: 2\nrelease: 2\n")
    write(File.join(release, "schema/core/api/v2.0.0/ion-beckn.yaml"), <<~YAML)
      paths:
        /confirm: {}
      components:
        schemas:
          ErrorCode:
            enum: [POL_ELIGIBILITY_NOT_MET, POL_GENERIC_ERROR]
    YAML
    write(File.join(release, "schema/core/api/v2.0.0/ion-additional.yaml"), "paths:\n  /reconcile: {}\n")
    write(File.join(release, "schema/extension/trade/TradeOffer/v1/attributes.yaml"), "openapi: 3.1.1\n")
    write(File.join(release, "flows/trade/patterns/storefront/v1/pattern.yaml"), "id: storefront\n")
    write(File.join(release, "errors/trade.yaml"), "[]\n")
    write(File.join(root, "policies/registry.json"), JSON.pretty_generate({"policies" => [{"iri" => "ion://policy/cancel.test.standard"}]}) + "\n")
    write(File.join(release, "rules/rego/ion/release2/trade/order.rego"), <<~REGO)
      package #{package_name}

      import rego.v1

      #{metadata}
      violations contains violation if {
      	violation := {"code": "POL_ELIGIBILITY_NOT_MET", "message": "[ION-R2-TRD-0001] test"}
      }
    REGO
    write(File.join(release, "rules/tests/trade/order_test.rego"), <<~REGO)
      package ion.release2.trade.order

      import rego.v1

      # Semantic coverage: #{test_rule_id}
      test_order_rule if {
      	true
      }
    REGO
    release
  end

  def valid_metadata(id: "ION-R2-TRD-0001", schema_path: "schema/extension/trade/TradeOffer/v1/attributes.yaml")
    <<~REGO.chomp
      # METADATA
      # title: Offer eligibility
      # description: Ensures the selected offer is eligible.
      # scope: rule
      # custom:
      #   ion_rule_id: #{id}
      #   sector: trade
      #   actions: [confirm]
      #   error_code: POL_ELIGIBILITY_NOT_MET
      #   status: active
      #   schema_paths: [#{schema_path}]
      #   flow_paths: [flows/trade/patterns/storefront/v1/pattern.yaml]
      #   error_paths: [errors/trade.yaml]
      #   policy_iris: ["ion://policy/cancel.test.standard"]
      #   config_keys: []
      #   data_paths: []
    REGO
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end
end
