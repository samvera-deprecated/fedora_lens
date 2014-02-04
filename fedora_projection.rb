require 'rdf'
require 'active_model'
require 'active_support/concern'
require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/hash'

module FedoraProjection
  extend ActiveSupport::Concern
  HOST = "http://localhost:8080"
  mattr_accessor :connection

  included do
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion

    class_attribute :defined_attributes
    self.defined_attributes = {}.with_indifferent_access

    def initialize(attributes = {})
      @attributes = attributes
    end
  end

  def persisted?()      false end

  def errors
    obj = Object.new
    def obj.[](key)         [] end
    def obj.full_messages() [] end
    obj
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end

  module ClassMethods
    def find(id)
      uri = RDF::URI.parse(HOST + id)
      graph = RDF::Graph.load(HOST + id, format: :ttl)
      attributes = defined_attributes.reduce({}) do |acc, pair|
        name, path = pair
        gets = path.map{|segment| build_lens(segment)}.map{|h| h[:get]}.reduce do |outer, inner|
          lambda {|*args| inner[outer[*args]]}
        end
        # acc[name] = path.first[:get].call(uri, graph)
        acc[name] = gets.call(uri, graph)
        acc
      end
      self.new(attributes)
    end

    def attribute(name, path, options={})
      defined_attributes[name] = path
      define_method name do
        @attributes[name]
      end
      define_method "#{name}=" do |value|
        @attributes[name] = value
        # @graph.delete([@id, path.last, nil])
        # @graph.insert([@id, path.last, value])
      end
    end

    def build_lens(path_segment)
      if path_segment.is_a? RDF::URI
        {
          get: lambda do |uri, graph|
            graph.query([uri, path_segment, nil]).map{|s| s.object.value}
          end
        }
      else
        path_segment
      end
    end

    def single
      {
        get: :first.to_proc, set: lambda{|x| [x]}
      }
    end

    def as_dom
      {
        # TODO figure out a memoizing strategy so we don't parse multiple times
        get: lambda {|xml| puts "parsing..."; Nokogiri::XML(xml)},
        set: lambda {|doc| doc.to_xml}
      }
    end
  end
end

class TestClass
  include FedoraProjection
  attribute :title, [RDF::DC.title, single]
  attribute :mixinTypes, [RDF::URI.new("http://fedora.info/definitions/v4/repository#mixinTypes")]
  attribute :primaryType, [RDF::URI.new("http://fedora.info/definitions/v4/repository#primaryType"), single]

  attribute :primary, [RDF::DC11.relation, single, as_dom,
    {
      get: lambda do |dom|
        dom.at_css("relationship[type=primary]").content
      end
    }]

  # eventually maybe do something like this:
  # attribute :secondary, [RDF::DC11.relation, single, css("relationship[type=secondary]")]
  attribute :secondary, [RDF::DC11.relation, single, as_dom,
    {
      get: lambda do |dom|
        dom.at_css("relationship[type=secondary]").content
      end
    }]
end
