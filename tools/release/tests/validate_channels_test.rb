#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "yaml"
require_relative "../validate_channels"

class ValidateChannelsTest < Minitest::Test
  def test_valid_first_release_next_assignment
    with_releases("release1" => "published") do |root|
      assert_empty IonReleaseChannels.validate(valid_channels, releases_root: root, require_next: "release1")
    end
  end

  def test_valid_inaugural_current_assignment
    with_releases("release1" => "published") do |root|
      channels = valid_channels.merge("current" => "release1", "next" => nil)

      assert_empty IonReleaseChannels.validate(channels, releases_root: root, require_channel: "release1")
    end
  end

  def test_required_channel_must_assign_release
    with_releases("release1" => "published") do |root|
      channels = valid_channels.merge("next" => nil)
      errors = IonReleaseChannels.validate(channels, releases_root: root, require_channel: "release1")

      assert_includes errors, "a channel must assign release1"
    end
  end

  def test_channel_release_must_be_published
    with_releases("release1" => "draft") do |root|
      errors = IonReleaseChannels.validate(valid_channels, releases_root: root, require_next: "release1")
      assert_includes errors, "channel release must be published: release1"
    end
  end

  def test_required_next_and_eligibility_are_enforced
    with_releases("release1" => "published") do |root|
      channels = valid_channels
      channels["next"]["release"] = "release2"
      channels["next"]["eligibleForCurrentAt"] = "2026-12-18T00:00:00Z"
      errors = IonReleaseChannels.validate(channels, releases_root: root, require_next: "release1")
      assert_includes errors, "next must assign release1"
      assert_includes errors, "next eligibleForCurrentAt must equal assignedAt plus minimumStabilizationDays"
    end
  end

  def test_release_may_not_occupy_multiple_channels
    with_releases("release1" => "published") do |root|
      channels = valid_channels.merge("current" => "release1")
      errors = IonReleaseChannels.validate(channels, releases_root: root)
      assert_includes errors, "release occupies more than one channel: release1"
    end
  end

  private

  def valid_channels
    {
      "schemaVersion" => 1,
      "current" => nil,
      "next" => {
        "release" => "release1",
        "assignedAt" => "2026-11-21T00:00:00Z",
        "minimumStabilizationDays" => 28,
        "eligibleForCurrentAt" => "2026-12-19T00:00:00Z"
      },
      "lts" => []
    }
  end

  def with_releases(statuses)
    Dir.mktmpdir do |root|
      statuses.each do |release, status|
        directory = File.join(root, release)
        FileUtils.mkdir_p(directory)
        File.write(File.join(directory, "release.yaml"), { "status" => status }.to_yaml)
      end
      yield root
    end
  end
end
