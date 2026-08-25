#!/usr/bin/env ruby

require "date"
require "find"
require "pathname"
require "uri"
require "yaml"

module IonOfflineRefs
  module_function

  def collect_refs(value, pointer = "", result = [])
    case value
    when Hash
      value.each do |key, child|
        child_pointer = "#{pointer}/#{escape_pointer(key)}"
        result << [child, child_pointer] if key == "$ref" && child.is_a?(String)
        collect_refs(child, child_pointer, result)
      end
    when Array
      value.each_with_index { |child, index| collect_refs(child, "#{pointer}/#{index}", result) }
    end
    result
  end

  def escape_pointer(value)
    value.to_s.gsub("~", "~0").gsub("/", "~1")
  end

  def resolve_pointer(document, fragment)
    return document if fragment.nil? || fragment.empty?
    raise ArgumentError, "fragment is not a JSON Pointer: ##{fragment}" unless fragment.start_with?("/")

    URI::DEFAULT_PARSER.unescape(fragment).split("/").drop(1).reduce(document) do |current, token|
      key = token.gsub("~1", "/").gsub("~0", "~")
      case current
      when Hash
        raise KeyError, "missing object key #{key.inspect}" unless current.key?(key)
        current.fetch(key)
      when Array
        raise KeyError, "invalid array index #{key.inspect}" unless key.match?(/\A(?:0|[1-9]\d*)\z/)
        index = Integer(key, 10)
        raise KeyError, "array index #{index} is out of bounds" unless index < current.length
        current.fetch(index)
      else
        raise KeyError, "cannot traverse #{key.inspect} through #{current.class}"
      end
    end
  end

  class Validator
    attr_reader :reference_count, :document_count, :errors

    def initialize(release_root)
      @release_root = File.expand_path(release_root)
      @public_base = "https://schema.ion.id/releases/#{File.basename(@release_root)}/"
      @documents = {}
      @errors = []
      @reference_count = 0
      @document_count = 0
    end

    def validate
      document_paths.each { |path| load_document(path) }
      @document_count = @documents.length
      @documents.each do |source_path, document|
        IonOfflineRefs.collect_refs(document).each do |ref, pointer|
          @reference_count += 1
          validate_ref(source_path, ref, pointer)
        end
      end
      errors.empty?
    end

    private

    def document_paths
      paths = []
      Find.find(@release_root) do |path|
        paths << path if File.file?(path) && path.match?(/\.(?:yaml|yml|json)\z/)
      end
      paths.sort
    end

    def load_document(path)
      @documents[path] ||= YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
    rescue Psych::SyntaxError => e
      @errors << "#{relative(path)}: invalid YAML/JSON: #{e.message.lines.first.strip}"
      nil
    end

    def validate_ref(source_path, ref, pointer)
      target_path, fragment = resolve_target(source_path, ref)
      unless target_path
        @errors << "#{relative(source_path)}#{pointer}: external or unsupported $ref #{ref.inspect}"
        return
      end
      unless File.file?(target_path)
        @errors << "#{relative(source_path)}#{pointer}: missing target #{relative(target_path)} for #{ref.inspect}"
        return
      end

      document = load_document(target_path)
      return unless document
      IonOfflineRefs.resolve_pointer(document, fragment)
    rescue ArgumentError, KeyError => e
      @errors << "#{relative(source_path)}#{pointer}: #{ref.inspect} does not resolve (#{e.message})"
    end

    def resolve_target(source_path, ref)
      document_ref, fragment = ref.split("#", 2)
      if document_ref.empty?
        [source_path, fragment]
      elsif document_ref.start_with?(@public_base)
        relative_target = document_ref.delete_prefix(@public_base)
        [contained_path(File.join(@release_root, relative_target)), fragment]
      elsif document_ref.match?(/\Ahttps?:\/\//)
        [nil, fragment]
      else
        [contained_path(File.expand_path(document_ref, File.dirname(source_path))), fragment]
      end
    rescue ArgumentError
      [nil, fragment]
    end

    def contained_path(path)
      expanded = File.expand_path(path)
      prefix = "#{@release_root}#{File::SEPARATOR}"
      raise ArgumentError, "target escapes release" unless expanded.start_with?(prefix)
      expanded
    end

    def relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(@release_root)).to_s
    rescue ArgumentError
      path
    end
  end
end

if $PROGRAM_NAME == __FILE__
  release_root = ARGV.fetch(0, "releases/release1")
  validator = IonOfflineRefs::Validator.new(release_root)
  if validator.validate
    puts "offline reference validation passed: #{validator.document_count} documents, #{validator.reference_count} references"
  else
    warn "offline reference validation failed with #{validator.errors.length} error(s):"
    validator.errors.each { |error| warn "- #{error}" }
    exit 1
  end
end
