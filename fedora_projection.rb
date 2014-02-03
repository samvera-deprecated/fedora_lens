require 'ldp'
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

    class_attribute :defined_attributes
    self.defined_attributes = {}#.with_indifferent_access

    def initialize(attributes = {})
      @attributes = attributes
    end
  end

  # def valid?()        true  end
  # def new_record?()   true  end
  # def destroyed?()    true  end
  def to_partial_path() ""    end
  def persisted?()      false end

  def to_model
    self
  end

  def to_key
    persisted? ? [:id] : nil
  end

  def to_param
    raise NotImplementedError if persisted?
  end

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
      # FedoraProjection.connection ||= Ldp::Client.new(HOST)
      # reader = RDF::Reader.for(:turtle).new(FedoraProjection.connection.get(id).body)
      # statements = reader.each_graph.first.statements.to_a
      graph = RDF::Graph.load(HOST + id, format: :ttl)
      attributes = defined_attributes.reduce({}) do |acc, pair|
        name, path = pair
        acc[name] = path.last[:get].call(uri, graph)
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

    def get_predicate(predicate, uri, graph)
      graph.query([uri, predicate, nil]).map{|s| s.object.value}
    end
  end
end

class TestClass
  include FedoraProjection
  # attribute :title, [RDF::DC.title]
  # attribute :xml_title, [RDF::DC.title]
  attribute :mixinTypes, [{
    get: lambda do |uri, statements|
      get_predicate(RDF::URI.new("http://fedora.info/definitions/v4/repository#mixinTypes"), uri, statements)
    end
  }]
  attribute :primaryType, [{
    get: lambda do |uri, statements|
      get_predicate(RDF::URI.new("http://fedora.info/definitions/v4/repository#primaryType"), uri, statements)
    end
  }]
end
