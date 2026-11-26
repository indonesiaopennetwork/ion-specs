require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../test_onix_integration"

class TestOnixIntegrationTest < Minitest::Test
  def test_rejects_a_non_onix_checkout_without_running_go
    Dir.mktmpdir("not-onix") do |directory|
      output = StringIO.new
      errors = StringIO.new

      refute IonOnixIntegration.run(onix_root: directory, out: output, err: errors)
      assert_includes errors.string, "not a beckn-onix checkout"
      assert_empty output.string
    end
  end

  def test_pin_is_a_full_git_revision
    revision = File.read(File.expand_path("../onix-revision", __dir__)).strip

    assert_match(/\A[0-9a-f]{40}\z/, revision)
  end
end
