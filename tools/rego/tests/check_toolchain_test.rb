#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "stringio"
require "tmpdir"
require_relative "../check_toolchain"

class CheckToolchainTest < Minitest::Test
  def test_matching_pinned_version_passes
    with_toolchain("1.15.2") do |root, executable|
      out = StringIO.new
      err = StringIO.new

      assert IonRegoToolchain.validate(repository_root: root, opa: executable, out: out, err: err)
      assert_includes out.string, "OPA toolchain check passed: 1.15.2"
      assert_empty err.string
    end
  end

  def test_mismatched_version_fails
    with_toolchain("1.14.0") do |root, executable|
      out = StringIO.new
      err = StringIO.new

      refute IonRegoToolchain.validate(repository_root: root, opa: executable, out: out, err: err)
      assert_includes err.string, "OPA version mismatch: expected 1.15.2, got 1.14.0"
    end
  end

  def test_missing_executable_fails_with_install_guidance
    Dir.mktmpdir do |root|
      write_version(root)
      err = StringIO.new

      refute IonRegoToolchain.validate(
        repository_root: root,
        opa: "missing-opa",
        out: StringIO.new,
        err: err,
        path_env: ""
      )
      assert_includes err.string, "Install OPA 1.15.2"
    end
  end

  private

  def with_toolchain(actual_version)
    Dir.mktmpdir do |root|
      write_version(root)
      executable = File.join(root, "opa")
      File.write(executable, "#!/bin/sh\nprintf 'Version: #{actual_version}\\n'\n")
      FileUtils.chmod(0o755, executable)
      yield root, executable
    end
  end

  def write_version(root)
    directory = File.join(root, "tools", "rego")
    FileUtils.mkdir_p(directory)
    File.write(File.join(directory, "opa-version"), "1.15.2\n")
  end
end
