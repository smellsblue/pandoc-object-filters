$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "pandoc_object_filters"
require "json"
require "minitest/autorun"
require "open3"
require "stringio"

class VersionCapturer
  def initialize
    @versions = {}
  end

  def v(number)
    @versions[number] = yield
  end

  def value
    current_version = PandocObjectFilters.current_pandoc_version.to_s
    raise "Missing version: #{current_version}" unless @versions.include?(current_version)
    @versions[current_version]
  end
end

module PandocVersionHelper
  def v(number, &block)
    raise "v must be called within a versioned block!" unless @_version_capturer
    @_version_capturer.v(number, &block)
  end

  def versioned
    VersionCapturer.new.tap do |capturer|
      raise "Cannot nest versioned calls!" if @_version_capturer
      @_version_capturer = capturer

      begin
        yield
      ensure
        @_version_capturer = nil
      end
    end.value
  end
end

module PandocHelper
  def ast_to_stream(ast)
    StringIO.new(JSON.dump(ast))
  end

  def stream_to_ast(stream)
    JSON.parse(stream.string)
  end

  def strip_whitespace(str)
    spaces = str[/^ +/]
    str.gsub /^#{spaces}/, ""
  end

  def to_pandoc_ast(markdown, strip: true)
    JSON.parse pandoc(markdown, to: "json")
  end

  def pandoc_exe
    ENV.fetch("PANDOC_EXE", "pandoc")
  end

  def pandoc(content, filter: nil, from: "markdown", to: "markdown", strip: true, standalone: true)
    content = strip_whitespace(content) if strip
    options = ["-f #{from}", "-t #{to}"]
    options << "-s" if standalone
    options << "--filter '#{filter}'" if filter
    output, status = Open3.capture2({ "RUBYLIB" => File.expand_path("../../lib", __FILE__) }, "#{pandoc_exe} #{options.join(' ')}", stdin_data: content)
    raise "Error capturing pandoc output!" unless status.success?
    output
  end
end

module PandocAstHelper
  def ast(type, value = [])
    VersionCapturer.new.tap do |capturer|
      capturer.v "1.16" do
        { "t" => type, "c" => value }
      end

      capturer.v "1.17" do
        if %w(Space SoftBreak LineBreak Null HorizontalRule).include?(type)
          { "t" => type }
        else
          { "t" => type, "c" => value }
        end
      end
    end.value
  end

  def hello_str_ast
    ast("Str", "hello")
  end

  def world_str_ast
    ast("Str", "world")
  end

  def space_ast
    ast("Space")
  end

  def soft_break_ast
    ast("SoftBreak")
  end

  def line_break_ast
    ast("LineBreak")
  end

  def null_ast
    ast("Null")
  end

  def para_ast(*children)
    ast("Para", children)
  end

  def plain_ast(*children)
    ast("Plain", children)
  end
end

module PandocElementHelper
  def hello_str
    PandocObjectFilters::Element::Str.new("hello")
  end

  def world_str
    PandocObjectFilters::Element::Str.new("world")
  end

  def space
    PandocObjectFilters::Element::Space.new
  end

  def soft_break
    PandocObjectFilters::Element::SoftBreak.new
  end

  def line_break
    PandocObjectFilters::Element::LineBreak.new
  end

  def null
    PandocObjectFilters::Element::Null.new
  end

  def para(*children)
    PandocObjectFilters::Element::Para.new(children)
  end

  def plain(*children)
    PandocObjectFilters::Element::Plain.new(children)
  end
end
