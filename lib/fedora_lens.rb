require 'rdf'
require 'ldp'
require 'ldp_monkeypatch'
require 'rdf/turtle'
require 'nokogiri'
require 'active_model'
require 'active_support/concern'
require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/hash'
require 'fedora_lens/errors'

module FedoraLens
  extend ActiveSupport::Concern
  HOST = "http://localhost:8080"

  def self.connection
    @@connection ||= Ldp::Client.new(HOST)
  end

  included do
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion

    class_attribute :attributes_as_lenses
    self.attributes_as_lenses = {}.with_indifferent_access

    attr_reader :attributes
    attr_reader :orm

    def initialize(data = {})
      case data
        when Ldp::Resource
          @orm = Ldp::Orm.new(data)
          @attributes = get_attributes_from_orm(@orm)
        when NilClass, Hash
          data ||= {}
          @orm = Ldp::Orm.new(Ldp::Resource.new(FedoraLens.connection, nil, RDF::Graph.new))
          @attributes = data.with_indifferent_access
        else
          raise ArgumentError, "#{data.class} is not acceptable"
        end
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

  def reload
    @orm = @orm.reload
    @attributes = get_attributes_from_orm(@orm)
  end

  def save
    @orm = self.class.orm_to_hash.put(@orm, @attributes)
    new_record? ? create_record : update_record
  end

  def save!
    save || raise(RecordNotSaved)
  end

  def new_record?
    !id.present?
  end

  def uri
    @orm.try(:resource).try(:subject_uri).try(:to_s)
  end

  def id
    URI.parse(uri).path.gsub(/\/rest/, '') if uri.present?
  end

  protected

    def create_record
      orm.tap do |orm|
        orm.resource.create
      end
    end

    def update_record
      # Fedora errors out when you try to set the rdf:type
      # see https://github.com/cbeer/ldp/issues/2
      orm.graph.delete([@orm.resource.subject_uri,
                         RDF::URI.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
                         nil])
      orm.save
      orm.last_response.success?
    end


  private

  def get_attributes_from_orm(orm)
    self.class.orm_to_hash.get(orm).with_indifferent_access
  end

  module ClassMethods
    def find(id)
      resource = Ldp::Resource.new(FedoraLens.connection, HOST + '/rest' + id)
      self.new(resource)
    end

    def attribute(name, path, options={})
      raise AttributeNotSupportedException if name.to_sym == :id
      attributes_as_lenses[name] = path.map{|s| coerce_to_lens(s)}
      define_method name do
        @attributes[name]
      end
      define_method "#{name}=" do |value|
        @attributes[name] = value
      end
      orm_to_hash = nil # force us to rebuild the aggregate_lens in case it was already built.
    end

    def create(data)
      model = self.new(data)
      model.save
      model
    end

    def orm_to_hash
      if @orm_to_hash.nil?
        aggregate_lens = attributes_as_lenses.reduce({}) do |acc, pair|
          name, path = pair
          lens = path.reduce {|outer, inner| Lenses.compose(outer, inner)}
          acc.merge(name => lens)
        end
        @orm_to_hash = Lenses.orm_to_hash(aggregate_lens)
      end
      @orm_to_hash
    end

    def coerce_to_lens(path_segment)
      if path_segment.is_a? RDF::URI
        Lenses.get_predicate(path_segment)
      else
        path_segment
      end
    end

    # def has_one(name, scope = nil, options = {})
    #   ActiveRecord::Associations::Builder::HasOne.build(self, name, scope, options)
    # end
  end
end

require 'fedora_lens/lenses'
