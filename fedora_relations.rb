require 'rubygems'
require 'ldp'
require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute'

module FedoraRelations
  extend ActiveSupport::Concern

  HOST = "http://localhost:8080"

  included do
    class_attribute :attribute_map
    self.attribute_map = {}
    def initialize(id, graph)
      @id = id
      @graph = graph
      @attributes = self.class.load_attributes(@graph, @id, attribute_map)
    end
  end

  module ClassMethods
    def find(id)
      uri = RDF::URI.parse(HOST + id)
      @connection ||= Ldp::Client.new(HOST)
      self.new(uri, RDF::Reader.for(:turtle).new(@connection.get(id)).each_graph.first)
    end

    def attribute(name, path, options={})
      attribute_map[name] = path
      define_method name do
        @attributes[name]
      end
      define_method "#{name}=" do |value|
        @graph.delete([@id, path.last, nil])
        @graph.insert([@id, path.last, value])
      end
    end

    def load_attributes(graph, id, attribute_map)
      attribute_map.reduce({}) do |acc, pair|
        name, path = pair
        acc[name] = graph.query([id, path.last, nil]).map(&:object)
      end
    end

    def save_attributes(graph, id, attribute_map, attributes)
      # FIXME use dirty tests to only update the ones that have changed
      attribute_map.each do |name, path|
        graph.delete([id, path.last, nil])
        graph.insert([id, path.last, value])
      end
    end
  end
end

class TestClass
  include FedoraRelations
  # attribute :title, [RDF::DC.title]
  attribute :title, [{
    get: lambda do |graph|
      graph.query([id, RDF::DC.title, nil])
    end
  }]

  # attribute :xml_title, [RDF::DC.title]
end
