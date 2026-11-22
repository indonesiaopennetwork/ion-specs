# frozen_string_literal: true

require_relative "test_helper"

class GeneratorTest < Minitest::Test
  include FixtureRepository

  def test_builds_role_specific_collections_with_required_hierarchy
    with_repository do |root, releases|
      seed_examples(releases)
      output = File.join(root, "output")

      paths = IonPostman::Generator.new(releases_root: releases, output_dir: output).call

      assert_equal [
        File.join(output, IonPostman::BUYER_FILENAME),
        File.join(output, IonPostman::SELLER_FILENAME)
      ], paths
      buyer = JSON.parse(File.read(paths[0]))
      seller = JSON.parse(File.read(paths[1]))

      buyer_request = item_at(buyer, "release1", "trade", "variants", "cancellation", "cancel_partial")
      assert_equal "POST", buyer_request.dig("request", "method")
      assert_equal "{{bap_adapter_url}}/cancel", buyer_request.dig("request", "url", "raw")
      assert_equal "Description for cancel_partial", buyer_request.dig("request", "description")
      buyer_body = JSON.parse(buyer_request.dig("request", "body", "raw"))
      assert_equal "cancel", buyer_body.dig("context", "action")
      assert_equal "{{transaction_id}}", buyer_body.dig("context", "transactionId")
      assert_equal "{{$guid}}", buyer_body.dig("context", "messageId")
      assert_equal "{{$isoTimestamp}}", buyer_body.dig("context", "timestamp")
      refute buyer_body.key?("_meta")
      item_at(buyer, "release2", "trade", "patterns", "storefront", "select")
      refute_includes request_items(buyer.fetch("item")).map { |item| item.fetch("name") }, "on_select"

      item_at(seller, "release2", "trade", "patterns", "storefront", "on_select")
      publish = item_at(seller, "release2", "trade", "patterns", "storefront", "publish_catalog")
      assert_equal "{{bpp_adapter_url}}/catalog/publish", publish.dig("request", "url", "raw")
      assert_equal %w[catalog publish], publish.dig("request", "url", "path")
      refute_includes request_items(seller.fetch("item")).map { |item| item.fetch("name") }, "select"

      expected_variables = {
        "bap_adapter_url" => "http://localhost:8081/bap/caller",
        "bpp_adapter_url" => "",
        "bap_id" => "",
        "base_url" => "",
        "bap_uri" => "{{base_url}}/bap/receiver",
        "bpp_id" => "",
        "bpp_uri" => "{{base_url}}/bpp/receiver",
        "networkId" => "",
        "transaction_id" => "",
        "bap_base_url" => "http://localhost:8081"
      }
      [buyer, seller].each do |collection|
        variables = collection.fetch("variable").to_h { |variable| [variable.fetch("key"), variable.fetch("value")] }
        assert_equal expected_variables, variables
      end
    end
  end

  def test_replaces_context_values_and_uses_a_unique_discover_transaction
    with_repository do |_root, releases|
      path = write_example(releases, release: "release1", name: "discover_text", action: "discover")
      payload = JSON.parse(File.read(path))
      payload["context"].merge!(
        "networkId" => "source-network",
        "bapId" => "source-bap",
        "bapUri" => "https://source.example/bap",
        "bppId" => "source-bpp",
        "bppUri" => "https://source.example/bpp",
        "transactionId" => "source-transaction",
        "messageId" => "source-message",
        "timestamp" => "2026-01-01T00:00:00Z"
      )
      payload["message"]["_meta"] = { "internal" => true }
      File.write(path, JSON.pretty_generate(payload))
      example = IonPostman::Discovery.new(releases).call.fetch(0)

      collection = IonPostman::CollectionBuilder.new(:buyer, [example]).call
      request = item_at(collection, "release1", "trade", "patterns", "storefront", "discover_text")
      body = JSON.parse(request.dig("request", "body", "raw"))

      assert_equal "{{networkId}}", body.dig("context", "networkId")
      assert_equal "{{bap_id}}", body.dig("context", "bapId")
      assert_equal "{{bap_uri}}", body.dig("context", "bapUri")
      assert_equal "{{bpp_id}}", body.dig("context", "bppId")
      assert_equal "{{bpp_uri}}", body.dig("context", "bppUri")
      assert_equal "{{$guid}}", body.dig("context", "transactionId")
      assert_equal "{{$guid}}", body.dig("context", "messageId")
      assert_equal "{{$isoTimestamp}}", body.dig("context", "timestamp")
      refute body.key?("_meta")
      refute body.fetch("message").key?("_meta")
      assert example.payload.key?("_meta"), "source payload must not be mutated"
      assert example.payload.fetch("message").key?("_meta"), "nested source metadata must remain intact"
    end
  end

  def test_orders_requests_by_transaction_action_then_name
    with_repository do |_root, releases|
      buyer_actions = %w[reconcile support update cancel rate track status confirm init select discover]
      seller_actions = %w[on_reconcile on_support on_update on_cancel on_rate on_track on_status on_confirm on_init on_select on_discover]
      buyer_actions.each { |action| write_example(releases, release: "release1", name: action, action: action) }
      seller_actions.each { |action| write_example(releases, release: "release1", name: action, action: action) }
      write_example(releases, release: "release1", name: "publish_catalog", action: "catalog/publish")
      examples = IonPostman::Discovery.new(releases).call

      buyer = IonPostman::CollectionBuilder.new(:buyer, examples).call
      seller = IonPostman::CollectionBuilder.new(:seller, examples).call
      buyer_folder = item_at(buyer, "release1", "trade", "patterns", "storefront")
      seller_folder = item_at(seller, "release1", "trade", "patterns", "storefront")

      assert_equal IonPostman::BUYER_ACTIONS, buyer_folder.fetch("item").map { |item| item.fetch("name") }
      assert_equal ["publish_catalog"] + IonPostman::SELLER_ACTIONS.drop(1), seller_folder.fetch("item").map { |item| item.fetch("name") }
    end
  end

  def test_orders_preview_examples_before_actual_messages
    with_repository do |_root, releases|
      %w[cancel_partial cancel cancel_preview].each do |name|
        write_example(releases, release: "release1", name: name, action: "cancel")
      end
      %w[on_update on_update_preview].each do |name|
        write_example(releases, release: "release1", name: name, action: "on_update")
      end
      examples = IonPostman::Discovery.new(releases).call

      buyer = IonPostman::CollectionBuilder.new(:buyer, examples).call
      seller = IonPostman::CollectionBuilder.new(:seller, examples).call
      buyer_folder = item_at(buyer, "release1", "trade", "patterns", "storefront")
      seller_folder = item_at(seller, "release1", "trade", "patterns", "storefront")

      assert_equal %w[cancel_preview cancel cancel_partial], buyer_folder.fetch("item").map { |item| item.fetch("name") }
      assert_equal %w[on_update_preview on_update], seller_folder.fetch("item").map { |item| item.fetch("name") }
    end
  end

  def test_output_is_deterministic_and_releases_are_sorted_numerically
    with_repository do |_root, releases|
      write_example(releases, release: "release10", name: "select", action: "select")
      write_example(releases, release: "release2", name: "select", action: "select")
      examples = IonPostman::Discovery.new(releases).call

      first = JSON.pretty_generate(IonPostman::CollectionBuilder.new(:buyer, examples).call)
      second = JSON.pretty_generate(IonPostman::CollectionBuilder.new(:buyer, examples.reverse).call)

      assert_equal first, second
      assert_equal %w[release2 release10], JSON.parse(first).fetch("item").map { |item| item.fetch("name") }
    end
  end

  def test_rejects_malformed_json
    with_repository do |_root, releases|
      path = write_example(releases, release: "release1", name: "select", action: "select")
      File.write(path, "{")

      error = assert_raises(IonPostman::Error) { IonPostman::Discovery.new(releases).call }

      assert_match(/invalid JSON/, error.message)
      assert_includes error.message, "select.json"
    end
  end

  def test_rejects_missing_action
    with_repository do |_root, releases|
      path = write_example(releases, release: "release1", name: "select", action: "select")
      File.write(path, JSON.generate("message" => {}))

      error = assert_raises(IonPostman::Error) { IonPostman::Discovery.new(releases).call }

      assert_match(/missing context\.action/, error.message)
    end
  end

  def test_rejects_unsupported_action
    with_repository do |_root, releases|
      write_example(releases, release: "release1", name: "mystery", action: "mystery")
      examples = IonPostman::Discovery.new(releases).call

      error = assert_raises(IonPostman::Error) do
        IonPostman::CollectionBuilder.new(:buyer, examples).call
      end

      assert_match(/unsupported action/, error.message)
    end
  end

  def test_rejects_an_empty_release
    with_repository do |_root, releases|
      FileUtils.mkdir_p(File.join(releases, "release1", "flows"))

      error = assert_raises(IonPostman::Error) { IonPostman::Discovery.new(releases).call }

      assert_match(/release contains no flow examples: release1/, error.message)
    end
  end

  def test_rejects_duplicate_request_names_after_version_is_omitted
    with_repository do |_root, releases|
      write_example(releases, release: "release1", version: "v1", name: "select", action: "select")
      write_example(releases, release: "release1", version: "v2", name: "select", action: "select")
      examples = IonPostman::Discovery.new(releases).call

      error = assert_raises(IonPostman::Error) do
        IonPostman::CollectionBuilder.new(:buyer, examples).call
      end

      assert_match(/duplicate generated request/, error.message)
      assert_includes error.message, "v1"
      assert_includes error.message, "v2"
    end
  end

  def test_refuses_to_overwrite_a_symlink
    with_repository do |root, _releases|
      target = File.join(root, "target.json")
      link = File.join(root, "output.json")
      File.write(target, "keep")
      File.symlink(target, link)

      error = assert_raises(IonPostman::Error) { IonPostman::AtomicWriter.write(link, "replace") }

      assert_match(/refusing to overwrite/, error.message)
      assert_equal "keep", File.read(target)
    end
  end
end
