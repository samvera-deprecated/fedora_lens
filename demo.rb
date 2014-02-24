require 'fedora_lens'
require 'active_support/core_ext/string'

module GenericFileRdfDatastream
  def self.mappings
    {
      part_of:        [RDF::DC.isPartOf],
      resource_type:  [RDF::DC.type],
      part_of:        [RDF::DC.isPartOf],
      resource_type:  [RDF::DC.type],
      title:          [RDF::DC.title],
      creator:        [RDF::DC.creator],
      contributor:    [RDF::DC.contributor],
      description:    [RDF::DC.description],
      tag:            [RDF::DC.relation],
      rights:         [RDF::DC.rights],
      publisher:      [RDF::DC.publisher],
      date_created:   [RDF::DC.created],
      date_uploaded:  [RDF::DC.dateSubmitted],
      date_modified:  [RDF::DC.modified],
      subject:        [RDF::DC.subject],
      language:       [RDF::DC.language],
      identifier:     [RDF::DC.identifier],
      based_near:     [RDF::FOAF.based_near],
      related_url:    [RDF::RDFS.seeAlso],
    }
  end
end

module Metadata
  extend ActiveSupport::Concern

  included do
    # has_metadata "descMetadata", type: GenericFileRdfDatastream
    # has_metadata "properties", type: PropertiesDatastream
    # has_file_datastream "content", type: FileContentDatastream
    # has_file_datastream "thumbnail"

    # has_attributes :relative_path, :depositor, :import_url, datastream: :properties, multiple: false
    has_attributes :date_uploaded, :date_modified, datastream: :descMetadata, multiple: false 
    has_attributes :related_url, :based_near, :part_of, :creator,
      :contributor, :title, :tag, :description, :rights,
      :publisher, :date_created, :subject,
      :resource_type, :identifier, :language, datastream: :descMetadata, multiple: true
  end

  def descMetadata
    {path: [RDF::URI.new('http://digitalcurationexperts.com/example#descMetadata'),
      FedoraLens::Lenses.single,
      FedoraLens::Lenses.load_resource],
      type: GenericFileRdfDatastream}
  end
  def properties
    {path: [RDF::URI.new('http://digitalcurationexperts.com/example#properties'),
      FedoraLens::Lenses.single,
      FedoraLens::Lenses.load_resource],
      type: PropertiesDatastream}
  end
  def has_attributes(*attributes)
    opts = attributes.pop
    attributes.each do |name|
      path = opts[:datastream][:path] + opts[:datastream][:type].mappings[name]
      path << FedoraLens::Lenses.single unless opts[:multiple]
      attribute name, path
    end
  end
end

class Example
  include FedoraLens
  include FedoraLens::Lenses
  extend Metadata
  has_attributes :date_uploaded, datastream: descMetadata, multiple: true
  has_attributes :title, datastream: descMetadata, multiple: true
end

# $LOAD_PATH << 'lib'
# load 'demo.rb'
# a = Example.new(title: "Some Title", related_url: "http://google.com", date_uploaded: Date.today)
# a.save
# id = a.id
# a = Example.find(id)
