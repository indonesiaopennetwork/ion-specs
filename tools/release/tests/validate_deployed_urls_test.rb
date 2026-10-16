#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../validate_deployed_urls"

class ValidateDeployedUrlsTest < Minitest::Test
  def test_validates_every_non_hidden_file_by_bytes_and_content_type
    Dir.mktmpdir do |root|
      write_fixture(root)
      responses = response_map(root)
      fetcher = ->(url) { responses.fetch(URI.parse(url).path.delete_prefix("/release9/")) }

      count, failures = IonDeployedUrls.validate(root, fetcher: fetcher, sleeper: nil)

      assert_equal 4, count
      assert_empty failures
    end
  end

  def test_reports_status_type_and_checksum_failures
    Dir.mktmpdir do |root|
      write_fixture(root)
      responses = response_map(root)
      responses["README.md"] = result(status: 404, type: "text/markdown", body: "")
      responses["schema/example.json"] = result(status: 200, type: "text/plain", body: "wrong")
      fetcher = ->(url) { responses.fetch(URI.parse(url).path.delete_prefix("/release9/")) }

      count, failures = IonDeployedUrls.validate(root, attempts: 1, fetcher: fetcher, sleeper: nil)

      assert_equal 4, count
      assert failures.any? { |failure| failure.include?("README.md: expected HTTP 200, got 404") }
      assert failures.any? { |failure| failure.include?("schema/example.json: expected Content-Type application/json") }
    end
  end

  def test_retries_only_failed_artifacts
    Dir.mktmpdir do |root|
      write_fixture(root)
      responses = response_map(root)
      calls = Hash.new(0)
      fetcher = lambda do |url|
        path = URI.parse(url).path.delete_prefix("/release9/")
        calls[path] += 1
        next result(status: 404, type: nil, body: "") if path == "schema/example.json" && calls[path] == 1

        responses.fetch(path)
      end
      sleeper = Object.new
      sleeper.define_singleton_method(:sleep) { |_seconds| nil }

      _count, failures = IonDeployedUrls.validate(root, attempts: 2, retry_delay: 0, fetcher: fetcher, sleeper: sleeper)

      assert_empty failures
      assert_equal 2, calls["schema/example.json"]
      assert_equal 1, calls["README.md"]
    end
  end

  private

  def write_fixture(root)
    FileUtils.mkdir_p(File.join(root, "schema"))
    File.write(File.join(root, "release.yaml"), "publicBaseUrl: https://example.test/release9/\n")
    File.write(File.join(root, "README.md"), "# Release 9\n")
    File.write(File.join(root, "schema", "example.json"), "{\"ok\":true}\n")
    File.write(File.join(root, "schema", ".DS_Store"), "ignored")
    File.write(File.join(root, "NOTICE"), "notice\n")
  end

  def response_map(root)
    {
      "release.yaml" => result(status: 200, type: "application/yaml", body: File.binread(File.join(root, "release.yaml"))),
      "README.md" => result(status: 200, type: "text/markdown", body: File.binread(File.join(root, "README.md"))),
      "schema/example.json" => result(status: 200, type: "application/json", body: File.binread(File.join(root, "schema", "example.json"))),
      "NOTICE" => result(status: 200, type: "application/octet-stream", body: File.binread(File.join(root, "NOTICE")))
    }
  end

  def result(status:, type:, body:)
    IonDeployedUrls::Result.new(status: status, content_type: type, body: body)
  end
end
