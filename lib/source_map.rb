require File.expand_path("../source_map/vlq.rb", __FILE__)
require File.expand_path("../source_map/generator.rb", __FILE__)

class SourceMap
  include SourceMap::Generator

  def initialize(opts={})
    self.generated_output = opts[:generated_output]
    self.file = opts[:file] || ''
    self.source_root = opts[:source_root] || ''
    raise "version #{opts[:version]} not supported" if opts[:version] && opts[:version] != 3
  end

  # The name of the generated file that this map is associated with.
  # (default "")
  attr_accessor :file

  # The base path/url to which the given source locations are relative.
  # (default "")
  attr_accessor :source_root

  # The version of the SourceMap spec to which this SourceMap responds.
  def version
    3
  end

  # The list of sources (used during parsing/generating)
  def sources
    @sources ||= []
  end

  # A list of names (used during parsing/generating)
  def names
    @names ||= []
  end

  # A list of mapping objects, see {add_mapping}
  def mappings
    @mappings ||= []
  end
end
