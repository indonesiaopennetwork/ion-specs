# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../lib/ion_postman"

module FixtureRepository
  def with_repository
    Dir.mktmpdir do |root|
      releases = File.join(root, "releases")
      yield root, releases
    end
  end

  def write_example(releases, release:, sector: "trade", kind: "patterns", flow: "storefront", version: "v1", name:, action:, metadata: true)
    directory = File.join(releases, release, "flows", sector, kind, flow, version, "examples")
    FileUtils.mkdir_p(directory)
    payload = {
      "context" => { "action" => action },
      "message" => { "example" => name }
    }
    payload["_meta"] = { "description" => "Description for #{name}" } if metadata
    path = File.join(directory, "#{name}.json")
    File.write(path, "#{JSON.pretty_generate(payload)}\n")
    path
  end

  def seed_examples(releases)
    write_example(releases, release: "release2", name: "select", action: "select")
    write_example(releases, release: "release2", name: "on_select", action: "on_select")
    write_example(releases, release: "release2", name: "publish_catalog", action: "catalog/publish")
    write_example(
      releases,
      release: "release1",
      kind: "variants",
      flow: "cancellation",
      name: "cancel_partial",
      action: "cancel"
    )
  end

  def item_at(collection, *names)
    names.reduce(collection) do |parent, name|
      parent.fetch("item").find { |item| item.fetch("name") == name } || flunk("missing item #{name}")
    end
  end

  def request_items(items)
    items.flat_map do |item|
      item.key?("request") ? [item] : request_items(item.fetch("item", []))
    end
  end
end
