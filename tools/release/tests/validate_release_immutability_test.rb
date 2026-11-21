#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "../validate_release_immutability"

class ValidateReleaseImmutabilityTest < Minitest::Test
  def test_only_published_releases_are_protected
    Dir.mktmpdir do |root|
      write_manifest(root, "release1", "published")
      write_manifest(root, "release2", "draft")
      assert_equal ["releases/release1"], IonReleaseImmutability.published_release_paths(File.join(root, "releases"))
    end
  end

  def test_changes_under_published_release_are_rejected
    errors = IonReleaseImmutability.validate(
      ["releases/release1"],
      ["README.md", "releases/release1/schema/common/Address/v1/attributes.yaml"]
    )
    assert_equal 1, errors.length
    assert_includes errors.first, "published release is immutable"
  end

  def test_existing_draft_may_transition_to_published
    errors = IonReleaseImmutability.validate_transitions(
      { "releases/release1" => "draft" },
      { "releases/release1" => "published" }
    )

    assert_empty errors
  end

  def test_new_release_may_not_appear_as_published
    errors = IonReleaseImmutability.validate_transitions(
      {},
      { "releases/release1" => "published" }
    )

    assert_equal ["published release must transition from an existing draft: releases/release1"], errors
  end

  private

  def write_manifest(root, name, status)
    directory = File.join(root, "releases", name)
    FileUtils.mkdir_p(directory)
    File.write(File.join(directory, "release.yaml"), "status: #{status}\n")
  end
end
