#!/usr/bin/env ruby

require "json"
require "optparse"
require "time"

options = {
  plan: "tools/release/release1-vendoring-plan.json",
  decision: nil
}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby tools/release/approve_vendoring_plan.rb --decision TEXT [--plan PATH]"
  opts.on("--plan PATH", "Proposed plan path") { |value| options[:plan] = value }
  opts.on("--decision TEXT", "Recorded maintainer decision") { |value| options[:decision] = value }
end
parser.parse!

unless options[:decision].is_a?(String) && !options[:decision].strip.empty?
  warn "ERROR: --decision is required"
  exit 2
end

begin
  plan = JSON.parse(File.read(options.fetch(:plan)))
rescue Errno::ENOENT, JSON::ParserError => e
  warn "ERROR: #{e.message}"
  exit 1
end

errors = []
errors << "plan status must be proposed" unless plan["status"] == "proposed"
errors << "blocking issues must be empty" unless plan["blockingIssues"] == []
errors << "protocol provenance must be verified" unless plan.dig("protocol", "provenanceStatus") == "verified"
errors << "all schema dependencies must be verified" unless plan.fetch("dependencies", []).all? { |entry| entry["provenanceStatus"] == "verified" }
errors << "all repository license checksums must be present" unless plan.fetch("repositories", []).all? { |entry| entry["sha256"].to_s.match?(/\A[0-9a-f]{64}\z/) }

unless errors.empty?
  errors.each { |error| warn "ERROR: #{error}" }
  exit 1
end

plan["status"] = "approved"
plan["approval"] = {
  "approvedAt" => Time.now.utc.iso8601,
  "decision" => options.fetch(:decision),
  "scope" => "The immutable commits and checksums in this plan only"
}
File.write(options.fetch(:plan), "#{JSON.pretty_generate(plan)}\n")
puts "approved vendoring plan: #{options.fetch(:plan)}"
