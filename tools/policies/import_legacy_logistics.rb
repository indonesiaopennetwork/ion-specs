#!/usr/bin/env ruby

require "fileutils"
require "open3"
require "optparse"
require "pathname"
require "yaml"

module IonLegacyLogisticsPolicies
  PINNED_SOURCE_COMMIT = "33e6b4c40feabecf6b0f6a827b488ff82998c735".freeze

  SOURCES = %w[
    policies/cancellation/v1/logistics-cancellation-policies.yaml
    policies/evidence/v1/standard-photo-24hr.yaml
    policies/incident/v1/standard.yaml
    policies/insurance/v1/standard-declared-value-cap.yaml
    policies/liability/v1/driver-and-force-majeure.yaml
    policies/liability/v1/loss-cap-per-shipment.yaml
    policies/penalty/v1/logistics-penalty-policies.yaml
    policies/re-attempt/v1/standard-3-free.yaml
    policies/rts-handoff/v1/standard.yaml
    policies/sla/v1/standard-95pct.yaml
    policies/weight-dispute/v1/standard-10pct-tolerance.yaml
  ].freeze

  POLICY_METADATA = {
    "cancel.logistics.prepickup-free" => ["cancellation", "logistics-prepickup-free", "Pembatalan gratis sebelum penjemputan", "Free cancellation before pickup"],
    "cancel.logistics.prepickup-futile-trip-fee" => ["cancellation", "logistics-prepickup-futile-trip-fee", "Pembatalan sebelum penjemputan dengan biaya perjalanan", "Pre-pickup cancellation with futile-trip fee"],
    "cancel.logistics.intransit-buyer-cost" => ["cancellation", "logistics-intransit-buyer-cost", "Pembatalan dalam perjalanan ditanggung pembeli", "In-transit cancellation at buyer cost"],
    "cancel.logistics.tat-breach-lsp-cost" => ["cancellation", "logistics-tat-breach-lsp-cost", "Pembatalan akibat pelanggaran TAT LSP", "Cancellation after LSP TAT breach"],
    "evidence.standard.photo-24hr" => ["evidence", "standard-photo-24hr", "Bukti foto standar dalam 24 jam", "Standard photo evidence within 24 hours"],
    "evidence.cold-chain.datalogger-required" => ["evidence", "cold-chain-datalogger-required", "Bukti pencatat data rantai dingin", "Cold-chain datalogger evidence required"],
    "incident.standard" => ["incident", "standard", "Pelaporan insiden logistik standar", "Standard logistics incident reporting"],
    "incident.high-severity-escalation" => ["incident", "high-severity-escalation", "Eskalasi insiden tingkat tinggi", "High-severity incident escalation"],
    "insurance.standard-declared-value-cap" => ["insurance", "standard-declared-value-cap", "Asuransi standar dengan batas nilai deklarasi", "Standard declared-value insurance cap"],
    "liability.force-majeure-exclusions" => ["liability", "force-majeure-exclusions", "Pengecualian tanggung jawab keadaan kahar", "Force-majeure liability exclusions"],
    "liability.loss-cap-per-shipment" => ["liability", "loss-cap-per-shipment", "Batas tanggung jawab kehilangan per kiriman", "Loss liability cap per shipment"],
    "liability.cod-max-per-shipment" => ["liability", "cod-max-per-shipment", "Batas tanggung jawab COD per kiriman", "COD liability cap per shipment"],
    "penalty.lsp-tat-breach" => ["penalty", "lsp-tat-breach", "Denda pelanggaran TAT LSP", "LSP TAT breach penalty"],
    "penalty.cod-remittance-late" => ["penalty", "cod-remittance-late", "Denda keterlambatan remitansi COD", "Late COD remittance penalty"],
    "penalty.pickup-failed.consignor-fault" => ["penalty", "pickup-failed-consignor-fault", "Denda kegagalan penjemputan akibat pengirim", "Pickup failure penalty for consignor fault"],
    "re-attempt.standard-3-free" => ["re-attempt", "standard-3-free", "Tiga upaya pengiriman ulang tanpa biaya", "Three free delivery attempts"],
    "re-attempt.hyperlocal-1-only" => ["re-attempt", "hyperlocal-1-only", "Satu upaya pengiriman hyperlocal", "One hyperlocal delivery attempt"],
    "re-attempt.standard-2-one-fee" => ["re-attempt", "standard-2-one-fee", "Dua upaya dengan biaya pada upaya kedua", "Two attempts with a fee on the second"],
    "rts-handoff.standard" => ["rts-handoff", "standard", "Serah terima siap dikirim standar", "Standard ready-to-ship handoff"],
    "rts-handoff.cross-bpp-timeout" => ["rts-handoff", "cross-bpp-timeout", "Batas waktu serah terima lintas BPP", "Cross-BPP handoff timeout"],
    "sla.standard-95pct" => ["sla", "standard-95pct", "SLA ketepatan waktu 95 persen", "Standard 95 percent on-time SLA"],
    "weight-dispute.standard-10pct-tolerance" => ["weight-dispute", "standard-10pct-tolerance", "Sengketa berat dengan toleransi 10 persen", "Weight dispute with 10 percent tolerance"]
  }.freeze

  REFERENCE_REWRITES = {
    "ion://policy/dispute-resolution.commercial-bani" => "ion://policy/dispute.commercial.bani",
    "ion://policy/dispute-resolution.commercial-odr" => "ion://policy/dispute.commercial.odr",
    "ion://policy/dispute-resolution.network-adjudication" => "ion://policy/dispute.commercial.odr"
  }.freeze

  module_function

  def import(source_root, repository_root, write: false, verify_revision: true)
    source_root = Pathname.new(File.expand_path(source_root))
    repository_root = Pathname.new(File.expand_path(repository_root))
    verify_source_revision(source_root) if verify_revision
    legacy_documents = load_legacy_documents(source_root)
    errors = []
    outputs = {}

    POLICY_METADATA.each do |legacy_id, metadata|
      source_path, legacy = legacy_documents[legacy_id]
      unless legacy
        errors << "missing legacy policy document: #{legacy_id}"
        next
      end

      category, filename, display_id, display_en = metadata
      output_path = repository_root.join("policies", category, "v1", "#{filename}.yaml")
      document = normalize(legacy, legacy_id, source_path, category, display_id, display_en)
      rendered = YAML.dump(document).sub(/\A---\n/, "")
      rendered = rendered.gsub(/^(versionEffectiveFrom|supersededBy|deprecatedAt):[ \t]*$/, '\\1: null')
      outputs[output_path] = rendered
    end

    return [outputs, errors] unless write && errors.empty?

    outputs.each do |path, rendered|
      path.dirname.mkpath
      path.write(rendered)
    end
    [outputs, errors]
  end

  def load_legacy_documents(source_root)
    documents = {}
    SOURCES.each do |relative_path|
      path = source_root.join(relative_path)
      raise "legacy policy source does not exist: #{path}" unless path.file?

      YAML.load_stream(File.read(path)).compact.each do |document|
        next unless document.is_a?(Hash) && document["id"]

        documents[document["id"]] = [relative_path, document]
      end
    end
    documents
  end

  def normalize(legacy, legacy_id, source_path, category, display_id, display_en)
    domain = deep_rewrite(legacy.reject { |key, _| %w[id type sector].include?(key) })
    {
      "iri" => "ion://policy/#{legacy_id}",
      "version" => "1.0.0",
      "versionEffectiveFrom" => nil,
      "category" => category.upcase.tr("-", "_"),
      "status" => "draft",
      "sector" => "logistics",
      "displayText" => { "id" => display_id, "en" => display_en },
      "applicableCategories" => ["logistics"],
      "applicableResourceTypes" => [],
      "regulatoryBasis" => [],
      "sourceProvenance" => {
        "repository" => "indonesiaopennetwork/ion-specs",
        "commit" => PINNED_SOURCE_COMMIT,
        "path" => source_path,
        "legacyId" => legacy_id
      },
      "supersededBy" => nil,
      "deprecatedAt" => nil
    }.merge(domain)
  end

  def deep_rewrite(value)
    case value
    when Hash
      value.each_with_object({}) { |(key, child), result| result[key] = deep_rewrite(child) }
    when Array
      value.map { |child| deep_rewrite(child) }
    when String
      REFERENCE_REWRITES.fetch(value, value)
    else
      value
    end
  end

  def verify_source_revision(source_root)
    output, status = Open3.capture2("git", "-C", source_root.to_s, "rev-parse", "HEAD")
    raise "cannot read legacy source revision: #{source_root}" unless status.success?

    actual = output.strip
    return if actual == PINNED_SOURCE_COMMIT

    raise "legacy source revision is #{actual}; expected #{PINNED_SOURCE_COMMIT}"
  end
end

if $PROGRAM_NAME == __FILE__
  options = { write: false, source_root: "../ion-specs-ion-launch" }
  OptionParser.new do |parser|
    parser.on("--write", "Write normalized draft policies") { options[:write] = true }
    parser.on("--source-root PATH", "Legacy ION repository root") { |path| options[:source_root] = path }
  end.parse!(ARGV)

  begin
    outputs, errors = IonLegacyLogisticsPolicies.import(
      options[:source_root],
      ARGV.fetch(0, "."),
      write: options[:write]
    )
    errors.each { |error| warn "ERROR: #{error}" }
    exit 1 unless errors.empty?

    action = options[:write] ? "wrote" : "would write"
    puts "#{action} #{outputs.length} reviewed Logistics policy documents"
  rescue StandardError => e
    warn e.message
    exit 2
  end
end
