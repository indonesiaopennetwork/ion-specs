require "json"
require "pathname"
require "yaml"

module IonRegoInventory
  RULE_ID = /\AION-R(?<release>\d+)-(?<area>COM|TRD|LOG|HSP)-\d{4}\z/.freeze
  CONFIG_KEY = /\A[a-z][A-Za-z0-9_]*(?:\.[a-z][A-Za-z0-9_]*)*\z/.freeze
  SECTOR_AREAS = { "common" => "COM", "trade" => "TRD", "logistics" => "LOG", "hospitality" => "HSP" }.freeze
  STATUSES = %w[active withdrawn].freeze
  METADATA_FIELDS = %w[title description scope custom].freeze
  CUSTOM_FIELDS = %w[
    ion_rule_id sector actions error_code status schema_paths flow_paths
    error_paths policy_iris config_keys data_paths
  ].freeze
  ARRAY_FIELDS = %w[
    actions schema_paths flow_paths error_paths policy_iris config_keys data_paths
  ].freeze

  module_function

  def build(release_root)
    root = Pathname.new(File.expand_path(release_root))
    repository_root = root.parent.parent
    manifest = YAML.safe_load(root.join("release.yaml").read, aliases: true)
    release = Integer(manifest.fetch("release"))
    rules_root = root.join("rules")
    source_files = Dir.glob(rules_root.join("rego/**/*.rego").to_s).sort.map { |path| Pathname.new(path) }
    test_files = Dir.glob(rules_root.join("tests/**/*_test.rego").to_s).sort.map { |path| Pathname.new(path) }
    errors = []
    records = []

    errors << "rules/rego: no production Rego modules found" if source_files.empty?
    errors << "rules/tests: no Rego test modules found" if test_files.empty?

    source_files.each do |path|
      relative = path.relative_path_from(root).to_s
      errors << "#{relative}: symlinks are not allowed" if symlink_in_path?(rules_root, path)
      errors << "#{relative}: test modules are not allowed under rules/rego" if path.basename.to_s.end_with?("_test.rego")
      text = path.read
      package = validate_production_module(root, rules_root.join("rego"), path, text, errors)
      annotations = extract_metadata(text, relative, errors)
      validate_rule_metadata_coverage(text, relative, annotations, errors)
      annotations.each do |annotation|
        record = validate_annotation(annotation, release, relative, package, errors)
        records << record if record
      end
    end

    test_files.each do |path|
      relative = path.relative_path_from(root).to_s
      errors << "#{relative}: symlinks are not allowed" if symlink_in_path?(rules_root, path)
      text = path.read
      errors << "#{relative}: must import rego.v1" unless text.match?(/^\s*import\s+rego\.v1\s*$/)
      errors << "#{relative}: must declare an ion.release#{release} package" unless text.match?(/^\s*package\s+ion\.release#{release}(?:\.[A-Za-z0-9_]+)*\s*$/)
    end

    validate_unique_ids(records, errors)
    validate_references(records, root, repository_root, errors)
    validate_config_usage(source_files, records, root, errors)
    validate_semantic_tests(records, test_files, root, errors)

    records.sort_by! { |record| record.fetch("id") }
    inventory = {
      "release" => release,
      "publicQuery" => "data.ion.release#{release}.result",
      "sourceFiles" => source_files,
      "testFiles" => test_files,
      "rules" => records
    }
    [inventory, errors]
  rescue Errno::ENOENT, Psych::SyntaxError, KeyError, ArgumentError => e
    [{ "rules" => [], "sourceFiles" => [], "testFiles" => [] }, [e.message.lines.first.strip]]
  end

  def validate_production_module(root, rules_root, path, text, errors)
    relative = path.relative_path_from(root).to_s
    errors << "#{relative}: must import rego.v1" unless text.match?(/^\s*import\s+rego\.v1\s*$/)
    packages = text.scan(/^\s*package\s+([^\s#]+)\s*$/).flatten
    if packages.length != 1
      errors << "#{relative}: must declare exactly one package"
      return nil
    end

    expected = expected_package(rules_root, path)
    actual = packages.first
    errors << "#{relative}: package must be #{expected}, got #{actual}" unless actual == expected
    if text.match?(/^\s*result\s*(?::=|=|contains|if\b)/) && relative != "rules/rego/ion/release#{release_from_path(path)}/policy.rego"
      errors << "#{relative}: public result is reserved for policy.rego"
    end
    actual
  end

  def expected_package(rules_root, path)
    parts = path.relative_path_from(rules_root).each_filename.to_a
    stem = File.basename(parts.pop, ".rego")
    return parts.join(".") if %w[policy helpers].include?(stem)

    (parts + [stem]).join(".")
  end

  def release_from_path(path)
    path.each_filename.find { |part| part.match?(/\Arelease\d+\z/) }.to_s.delete_prefix("release")
  end

  def extract_metadata(text, relative, errors)
    lines = text.lines
    annotations = []
    lines.each_with_index do |line, index|
      next unless line.match?(/^[ \t]*#[ \t]*METADATA[ \t]*$/)

      yaml_lines = []
      cursor = index + 1
      while cursor < lines.length && lines[cursor].match?(/^[ \t]*#/)
        yaml_lines << lines[cursor].sub(/^[ \t]*#[ ]?/, "")
        cursor += 1
      end
      declaration = lines[cursor].to_s.strip
      rule_name = declaration[/\A([A-Za-z_][A-Za-z0-9_]*)\s*(?:contains\b|:=|=|if\b|\[)/, 1]
      unless rule_name
        errors << "#{relative}:#{index + 1}: metadata must immediately precede a rule declaration"
        next
      end

      begin
        metadata = YAML.safe_load(yaml_lines.join, aliases: false)
        unless metadata.is_a?(Hash)
          errors << "#{relative}:#{index + 1}: metadata must be a YAML object"
          next
        end
        annotations << {
          "metadata" => metadata,
          "line" => index + 1,
          "declarationLine" => cursor + 1,
          "ruleName" => rule_name
        }
      rescue Psych::SyntaxError => e
        errors << "#{relative}:#{index + 1}: malformed metadata: #{e.problem}"
      end
    end
    annotations
  end

  def validate_rule_metadata_coverage(text, relative, annotations, errors)
    return if relative.match?(%r{\Arules/rego/ion/release\d+/policy\.rego\z})

    annotated_lines = annotations.map { |annotation| annotation.fetch("declarationLine") }
    text.lines.each_with_index do |line, index|
      next unless line.match?(/^\s*(?:[A-Za-z_][A-Za-z0-9_]*_)?violations\s+contains\b/)
      next if annotated_lines.include?(index + 1)

      errors << "#{relative}:#{index + 1}: violation rule must have immediately preceding METADATA"
    end
  end

  def validate_annotation(annotation, release, relative, package, errors)
    metadata = annotation.fetch("metadata")
    location = "#{relative}:#{annotation.fetch('line')}"
    %w[title description scope custom].each do |field|
      errors << "#{location}: metadata missing #{field}" unless metadata.key?(field)
    end
    (metadata.keys - METADATA_FIELDS).each do |field|
      errors << "#{location}: unknown metadata field #{field}"
    end
    errors << "#{location}: metadata scope must be rule" unless metadata["scope"] == "rule"
    %w[title description].each do |field|
      errors << "#{location}: metadata #{field} must be a non-empty string" unless non_empty_string?(metadata[field])
    end
    custom = metadata["custom"]
    unless custom.is_a?(Hash)
      errors << "#{location}: metadata custom must be an object"
      return nil
    end

    required = %w[ion_rule_id sector actions error_code status]
    required.each { |field| errors << "#{location}: custom metadata missing #{field}" unless custom.key?(field) }
    (custom.keys - CUSTOM_FIELDS).each do |field|
      errors << "#{location}: unknown custom metadata field #{field}"
    end
    id = custom["ion_rule_id"].to_s
    match = RULE_ID.match(id)
    unless match && match[:release].to_i == release
      errors << "#{location}: invalid rule ID #{id.inspect}; expected ION-R#{release}-(COM|TRD|LOG|HSP)-NNNN"
    end
    sector = custom["sector"]
    unless SECTOR_AREAS.key?(sector)
      errors << "#{location}: sector must be common, trade, logistics, or hospitality"
    end
    if match && SECTOR_AREAS[sector] && match[:area] != SECTOR_AREAS.fetch(sector)
      errors << "#{location}: rule ID area #{match[:area]} does not match sector #{sector}"
    end
    errors << "#{location}: status must be active or withdrawn" unless STATUSES.include?(custom["status"])
    errors << "#{location}: error_code must use the POL_* taxonomy" unless custom["error_code"].to_s.match?(/\APOL_[A-Z0-9_]+\z/)

    ARRAY_FIELDS.each do |field|
      value = custom.fetch(field, [])
      unless value.is_a?(Array) && value.all? { |entry| non_empty_string?(entry) }
        errors << "#{location}: #{field} must be an array of non-empty strings"
      end
      errors << "#{location}: #{field} must not contain duplicates" if value.is_a?(Array) && value.uniq.length != value.length
    end
    errors << "#{location}: actions must contain at least one action" if custom["actions"].is_a?(Array) && custom["actions"].empty?

    {
      "id" => id,
      "title" => metadata["title"],
      "description" => metadata["description"],
      "sector" => sector,
      "actions" => array_value(custom, "actions"),
      "package" => package,
      "ruleName" => annotation.fetch("ruleName"),
      "sourceModule" => relative,
      "errorCode" => custom["error_code"],
      "schemaPaths" => array_value(custom, "schema_paths"),
      "flowPaths" => array_value(custom, "flow_paths"),
      "errorPaths" => array_value(custom, "error_paths"),
      "policyIris" => array_value(custom, "policy_iris"),
      "configKeys" => array_value(custom, "config_keys"),
      "dataPaths" => array_value(custom, "data_paths"),
      "status" => custom["status"]
    }
  end

  def array_value(custom, field)
    custom[field].is_a?(Array) ? custom[field].sort : []
  end

  def non_empty_string?(value)
    value.is_a?(String) && !value.strip.empty?
  end

  def validate_unique_ids(records, errors)
    records.group_by { |record| record["id"] }.each do |id, entries|
      errors << "duplicate rule ID #{id}: #{entries.map { |entry| entry['sourceModule'] }.join(', ')}" if entries.length > 1
    end
  end

  def validate_references(records, root, repository_root, errors)
    actions = allowed_actions(root, errors)
    error_codes = allowed_error_codes(root, errors)
    policy_iris = allowed_policy_iris(repository_root, errors)
    records.each do |record|
      record["actions"].each do |action|
        errors << "#{record['id']}: unknown action #{action}" unless actions.include?(action)
      end
      unless error_codes.include?(record["errorCode"])
        errors << "#{record['id']}: unresolved protocol error code #{record['errorCode']}"
      end
      {
        "schemaPaths" => "schema/",
        "flowPaths" => "flows/",
        "errorPaths" => "errors/"
      }.each do |field, prefix|
        record[field].each { |value| validate_release_path(record["id"], value, prefix, root, errors) }
      end
      record["policyIris"].each do |iri|
        errors << "#{record['id']}: invalid policy IRI #{iri}" unless iri.match?(/\Aion:\/\/policy\/[a-z0-9][a-z0-9.-]*\z/)
        errors << "#{record['id']}: unresolved policy IRI #{iri}" unless policy_iris.include?(iri)
      end
      record["configKeys"].each do |key|
        errors << "#{record['id']}: invalid config key #{key}" unless key.match?(CONFIG_KEY)
      end
      record["dataPaths"].each do |path|
        expected = "data.ion.release#{record['id'][/\AION-R(\d+)-/, 1]}."
        errors << "#{record['id']}: data path must begin #{expected}" unless path.start_with?(expected)
      end
    end
  end

  def validate_release_path(id, value, prefix, root, errors)
    path = Pathname.new(value)
    if path.absolute? || path.each_filename.to_a.include?("..") || !value.start_with?(prefix)
      errors << "#{id}: unsafe or misclassified release path #{value.inspect}; expected #{prefix}..."
      return
    end
    candidate = root.join(path)
    errors << "#{id}: unresolved release path #{value}" unless candidate.file?
    errors << "#{id}: release path must not traverse a symlink: #{value}" if candidate.exist? && symlink_in_path?(root, candidate)
  end

  def symlink_in_path?(root, path)
    relative = Pathname.new(path).relative_path_from(Pathname.new(root))
    current = Pathname.new(root)
    relative.each_filename.any? do |part|
      current = current.join(part)
      current.symlink?
    end
  rescue ArgumentError
    true
  end

  def allowed_actions(root, errors)
    paths = root.join("schema/core/api/v2.0.0")
    actions = []
    Dir.glob(paths.join("*.yaml").to_s).sort.each do |path|
      document = YAML.safe_load(File.read(path), aliases: true)
      actions.concat(document.fetch("paths", {}).keys.map { |entry| entry.delete_prefix("/") })
    end
    actions.uniq
  rescue Psych::SyntaxError => e
    errors << "cannot read protocol actions: #{e.problem}"
    []
  end

  def allowed_error_codes(root, errors)
    path = root.join("schema/core/api/v2.0.0/ion-beckn.yaml")
    document = YAML.safe_load(path.read, aliases: true)
    document.dig("components", "schemas", "ErrorCode", "enum") || []
  rescue Psych::SyntaxError => e
    errors << "cannot read protocol error taxonomy: #{e.problem}"
    []
  end

  def allowed_policy_iris(repository_root, errors)
    registry = JSON.parse(repository_root.join("policies/registry.json").read)
    registry.fetch("policies").map { |policy| policy.fetch("iri") }
  rescue JSON::ParserError, KeyError => e
    errors << "cannot read shared policy registry: #{e.message}"
    []
  end

  def validate_config_usage(source_files, records, root, errors)
    declarations = records.group_by { |record| record["sourceModule"] }
    source_files.each do |path|
      relative = path.relative_path_from(root).to_s
      used = path.read.scan(/\bdata\.config\.([A-Za-z0-9_.]+)/).flatten.uniq.sort
      declared = declarations.fetch(relative, []).flat_map { |record| record["configKeys"] }.uniq
      (used - declared).each { |key| errors << "#{relative}: data.config.#{key} is not declared in rule metadata" }
      if path.read.match?(/\bdata\.config\s*\[/)
        errors << "#{relative}: dynamic data.config access cannot be validated; use a declared dotted key"
      end
    end
  end

  def validate_semantic_tests(records, test_files, root, errors)
    test_text = test_files.map(&:read).join("\n")
    records.each do |record|
      next if record["status"] == "withdrawn"
      next if test_text.include?(record["id"])

      errors << "#{record['id']}: no semantic test references this rule ID under #{root.join('rules/tests')}"
    end
  end
end
