# frozen_string_literal: true

require_relative "test_helper"

class CLITest < Minitest::Test
  include FixtureRepository

  def test_cli_generates_both_collections
    with_repository do |root, releases|
      seed_examples(releases)
      output = File.join(root, "generated")
      stdout = StringIO.new
      stderr = StringIO.new

      status = IonPostman::CLI.run(
        ["--releases", releases, "--output-dir", output],
        stdout: stdout,
        stderr: stderr
      )

      assert_equal 0, status
      assert_empty stderr.string
      assert File.file?(File.join(output, IonPostman::BUYER_FILENAME))
      assert File.file?(File.join(output, IonPostman::SELLER_FILENAME))
      assert_equal 2, stdout.string.lines.length
    end
  end

  def test_cli_returns_failure_for_invalid_input
    stdout = StringIO.new
    stderr = StringIO.new

    status = IonPostman::CLI.run(
      ["--releases", "/path/that/does/not/exist"],
      stdout: stdout,
      stderr: stderr
    )

    assert_equal 1, status
    assert_empty stdout.string
    assert_match(/releases directory does not exist/, stderr.string)
    assert_match(/Usage:/, stderr.string)
  end

  def test_help_uses_injected_output_and_does_not_generate
    stdout = StringIO.new
    stderr = StringIO.new

    status = IonPostman::CLI.run(["--help"], stdout: stdout, stderr: stderr)

    assert_equal 0, status
    assert_match(/Usage: ruby generate_collections\.rb/, stdout.string)
    assert_empty stderr.string
  end
end
