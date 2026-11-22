# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "optparse"
require "pathname"
require "tempfile"

module IonPostman
  BUYER_FILENAME = "IONBuyerAppStarter.postman_collection.json"
  SELLER_FILENAME = "IONSellerAppStarter.postman_collection.json"
  BUYER_ACTIONS = %w[
    discover select init confirm status track rate cancel update support reconcile
  ].freeze
  SELLER_ACTIONS = (["catalog/publish"] + BUYER_ACTIONS.map { |action| "on_#{action}" }).freeze
  ACTION_ORDER = { buyer: BUYER_ACTIONS, seller: SELLER_ACTIONS }.freeze
  CONTEXT_PLACEHOLDERS = {
    "networkId" => "{{networkId}}",
    "bapId" => "{{bap_id}}",
    "bapUri" => "{{bap_uri}}",
    "bppId" => "{{bpp_id}}",
    "bppUri" => "{{bpp_uri}}",
    "messageId" => "{{$guid}}",
    "timestamp" => "{{$isoTimestamp}}"
  }.freeze
  COLLECTION_VARIABLES = [
    ["bap_adapter_url", "http://localhost:8081/bap/caller"],
    ["bpp_adapter_url", ""],
    ["bap_id", ""],
    ["base_url", ""],
    ["bap_uri", "{{base_url}}/bap/receiver"],
    ["bpp_id", ""],
    ["bpp_uri", "{{base_url}}/bpp/receiver"],
    ["networkId", ""],
    ["transaction_id", ""],
    ["bap_base_url", "http://localhost:8081"]
  ].freeze
  POSTMAN_SCHEMA = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"

  class Error < StandardError; end

  Example = Struct.new(
    :source_path,
    :release,
    :release_number,
    :sector,
    :kind,
    :flow,
    :version,
    :name,
    :action,
    :payload,
    keyword_init: true
  )

  class Discovery
    def initialize(releases_root)
      @releases_root = Pathname.new(File.expand_path(releases_root))
    end

    def call
      validate_root!
      examples = release_directories.flat_map { |directory| discover_release(directory) }
      examples.sort_by do |example|
        [example.release_number, example.sector, example.kind, example.flow, example.version, example.name]
      end
    end

    private

    def validate_root!
      return if @releases_root.directory?

      raise Error, "releases directory does not exist: #{@releases_root}"
    end

    def release_directories
      directories = @releases_root.children.select do |path|
        path.directory? && path.basename.to_s.match?(/\Arelease[1-9]\d*\z/)
      end
      raise Error, "no release directories found under #{@releases_root}" if directories.empty?

      directories.sort_by { |path| release_number(path.basename.to_s) }
    end

    def discover_release(directory)
      paths = Dir.glob(directory.join("flows", "**", "examples", "*").to_s).select { |path| File.file?(path) }.sort
      raise Error, "release contains no flow examples: #{directory.basename}" if paths.empty?

      paths.map { |path| load_example(Pathname.new(path)) }
    end

    def load_example(path)
      relative = path.relative_path_from(@releases_root)
      parts = relative.each_filename.to_a
      unless valid_path?(parts)
        raise Error, "unsupported flow example path: #{relative}"
      end
      raise Error, "flow example must be JSON: #{relative}" unless path.extname == ".json"

      payload = JSON.parse(path.read)
      raise Error, "flow example root must be an object: #{relative}" unless payload.is_a?(Hash)

      action = payload.dig("context", "action")
      unless action.is_a?(String) && !action.empty?
        raise Error, "flow example is missing context.action: #{relative}"
      end

      release, _flows, sector, kind, flow, version, _examples, filename = parts
      Example.new(
        source_path: path.to_s,
        release: release,
        release_number: release_number(release),
        sector: sector,
        kind: kind,
        flow: flow,
        version: version,
        name: File.basename(filename, ".json"),
        action: action,
        payload: payload
      )
    rescue JSON::ParserError => e
      raise Error, "invalid JSON in #{relative}: #{e.message}"
    end

    def valid_path?(parts)
      parts.length == 8 &&
        parts[0].match?(/\Arelease[1-9]\d*\z/) &&
        parts[1] == "flows" &&
        !parts[2].empty? &&
        %w[patterns variants].include?(parts[3]) &&
        !parts[4].empty? &&
        parts[5].match?(/\Av[1-9]\d*\z/) &&
        parts[6] == "examples" &&
        !parts[7].empty?
    end

    def release_number(name)
      Integer(name.delete_prefix("release"), 10)
    end
  end

  class Router
    def self.role_for(example)
      return :buyer if BUYER_ACTIONS.include?(example.action)
      return :seller if SELLER_ACTIONS.include?(example.action)

      raise Error, "unsupported action #{example.action.inspect} in #{example.source_path}"
    end
  end

  class PayloadTransformer
    def self.call(payload, action)
      transformed = without_metadata(payload)
      context = transformed["context"]
      unless context.is_a?(Hash)
        raise Error, "flow example context must be an object"
      end

      CONTEXT_PLACEHOLDERS.each { |key, value| context[key] = value }
      context["transactionId"] = action == "discover" ? "{{$guid}}" : "{{transaction_id}}"
      transformed
    end

    def self.without_metadata(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, child), result|
          result[key] = without_metadata(child) unless key == "_meta"
        end
      when Array
        value.map { |child| without_metadata(child) }
      else
        value
      end
    end
    private_class_method :without_metadata
  end

  class CollectionBuilder
    DEFINITIONS = {
      buyer: {
        name: "ION Starter Kit Buyer App",
        description: "ION buyer-side requests generated from release flow examples."
      },
      seller: {
        name: "ION Starter Kit Seller App",
        description: "ION seller and discovery-service requests generated from release flow examples."
      }
    }.freeze

    def initialize(role, examples)
      @role = role
      @definition = DEFINITIONS.fetch(role)
      @examples = examples.select { |example| Router.role_for(example) == role }
    end

    def call
      validate_unique_destinations!
      {
        "info" => {
          "_postman_id" => deterministic_id(@definition.fetch(:name)),
          "name" => @definition.fetch(:name),
          "description" => @definition.fetch(:description),
          "schema" => POSTMAN_SCHEMA
        },
        "item" => folder_items,
        "variable" => collection_variables
      }
    end

    private

    def validate_unique_destinations!
      destinations = @examples.group_by do |example|
        [example.release, example.sector, example.kind, example.flow, example.name]
      end
      duplicate = destinations.find { |_destination, examples| examples.length > 1 }
      return unless duplicate

      destination, examples = duplicate
      sources = examples.map(&:source_path).sort.join(", ")
      raise Error, "duplicate generated request #{destination.join('/')}: #{sources}"
    end

    def folder_items
      tree = {}
      @examples.each do |example|
        node = tree
        [example.release, example.sector, example.kind, example.flow].each do |segment|
          node[segment] ||= { children: {}, requests: [] }
          node = node.fetch(segment).fetch(:children)
        end
        parent = tree.dig(example.release, :children, example.sector, :children, example.kind, :children, example.flow)
        parent.fetch(:requests) << request_item(example)
      end
      serialize_nodes(tree)
    end

    def serialize_nodes(nodes)
      nodes.keys.sort_by { |name| folder_sort_key(name) }.map do |name|
        node = nodes.fetch(name)
        children = serialize_nodes(node.fetch(:children))
        requests = node.fetch(:requests).sort_by { |request| request_sort_key(request) }
        { "name" => name, "item" => children + requests }
      end
    end

    def request_sort_key(request)
      action = request.dig("request", "url", "path").join("/")
      name = request.fetch("name")
      preview_rank = name.include?("_preview") ? 0 : 1
      [ACTION_ORDER.fetch(@role).index(action), preview_rank, name]
    end

    def folder_sort_key(name)
      match = name.match(/\Arelease(\d+)\z/)
      match ? [0, match[1].to_i] : [1, name]
    end

    def request_item(example)
      payload = PayloadTransformer.call(example.payload, example.action)
      adapter_variable = @role == :buyer ? "bap_adapter_url" : "bpp_adapter_url"
      request = {
        "method" => "POST",
        "header" => [
          { "key" => "Content-Type", "value" => "application/json", "type" => "text" }
        ],
        "body" => {
          "mode" => "raw",
          "raw" => "#{JSON.pretty_generate(payload)}\n",
          "options" => { "raw" => { "language" => "json" } }
        },
        "url" => {
          "raw" => "{{#{adapter_variable}}}/#{example.action}",
          "host" => ["{{#{adapter_variable}}}"],
          "path" => example.action.split("/")
        }
      }
      description = example.payload.dig("_meta", "description")
      request["description"] = description if description.is_a?(String) && !description.empty?
      { "name" => example.name, "request" => request, "response" => [] }
    end

    def collection_variables
      COLLECTION_VARIABLES.map do |key, value|
        { "key" => key, "value" => value, "type" => "string" }
      end
    end

    def deterministic_id(name)
      hex = Digest::SHA256.hexdigest(name)[0, 32]
      [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join("-")
    end
  end

  class AtomicWriter
    def self.write(path, content)
      expanded = File.expand_path(path)
      FileUtils.mkdir_p(File.dirname(expanded))
      if File.symlink?(expanded) || (File.exist?(expanded) && !File.file?(expanded))
        raise Error, "refusing to overwrite non-regular output: #{expanded}"
      end

      temporary = Tempfile.new([".ion-postman-", ".json"], File.dirname(expanded))
      begin
        temporary.write(content)
        temporary.flush
        temporary.fsync
        temporary.close
        File.rename(temporary.path, expanded)
      ensure
        temporary.close unless temporary.closed?
        temporary.unlink if File.exist?(temporary.path)
      end
    end
  end

  class Generator
    def initialize(releases_root:, output_dir:)
      @releases_root = releases_root
      @output_dir = File.expand_path(output_dir)
    end

    def call
      examples = Discovery.new(@releases_root).call
      outputs = {
        BUYER_FILENAME => CollectionBuilder.new(:buyer, examples).call,
        SELLER_FILENAME => CollectionBuilder.new(:seller, examples).call
      }
      outputs.each do |filename, collection|
        AtomicWriter.write(File.join(@output_dir, filename), "#{JSON.pretty_generate(collection)}\n")
      end
      outputs.keys.map { |filename| File.join(@output_dir, filename) }
    end
  end

  class CLI
    TOOL_ROOT = File.expand_path("..", __dir__)
    REPOSITORY_ROOT = File.expand_path("../..", TOOL_ROOT)

    def self.run(arguments, stdout: $stdout, stderr: $stderr)
      options = {
        releases_root: File.join(REPOSITORY_ROOT, "releases"),
        output_dir: TOOL_ROOT
      }
      parser = option_parser(options)
      parser.parse!(arguments)
      raise OptionParser::InvalidArgument, "unexpected arguments: #{arguments.join(' ')}" unless arguments.empty?
      if options.delete(:help)
        stdout.puts parser
        return 0
      end

      paths = Generator.new(
        releases_root: options.fetch(:releases_root),
        output_dir: options.fetch(:output_dir)
      ).call
      paths.each { |path| stdout.puts "generated #{path}" }
      0
    rescue OptionParser::ParseError, Error => e
      stderr.puts "ERROR: #{e.message}"
      stderr.puts parser
      1
    end

    def self.option_parser(options)
      OptionParser.new do |parser|
        parser.banner = "Usage: ruby generate_collections.rb [options]"
        parser.on("--releases PATH", "Releases directory (default: repository releases/)") do |path|
          options[:releases_root] = path
        end
        parser.on("--output-dir PATH", "Directory for the two generated collections") do |path|
          options[:output_dir] = path
        end
        parser.on("-h", "--help", "Show this help") do
          options[:help] = true
        end
      end
    end
  end
end
