require 'fedora_lens'
class TestClass
  include FedoraLens
  include FedoraLens::Lenses

  def self.custom_lens(type)
    Lens[
      get: lambda do |doc|
        if node = doc.at_css("relationship[type=#{type}]")
          node.content
        else
          ""
        end
      end,
      put: lambda do |doc, value|
        # TODO: create missing nodes
        # doc.at_css(selector).content = value; doc
        doc << Nokogiri::XML::Node.new("relationships", doc) if doc.root.nil?
        root = doc.root
        relationship = root.at_css("relationship[type=#{type}]")
        if relationship.nil?
          relationship = Nokogiri::XML::Node.new("relationship", doc)
          relationship.set_attribute("type", type)
          root << relationship
        end
        relationship.content = value
        doc
      end,
      create: lambda do |value|
        Nokogiri::XML("<relationships>
          <relationship type=\"#{type}\">#{value}</relationship>
        </relationships>")
      end
    ]
  end

  attribute :title, [RDF::DC11.title, Lenses.first, Lenses.literal_to_string]
  attribute :mixinTypes, [
    RDF::URI.new("http://fedora.info/definitions/v4/repository#mixinTypes")]
  attribute :primaryType, [
    RDF::URI.new("http://fedora.info/definitions/v4/repository#primaryType"),
    Lenses.first,
    Lenses.literal_to_string]
  attribute :primary_id, [
    RDF::DC11.relation,
    Lenses.first,
    Lenses.literal_to_string,
    Lenses.as_dom,
    # Lenses.at_css("relationship[type=primary]")]
    custom_lens("primary")]
  attribute :secondary, [
    RDF::DC11.relation,
    Lenses.first,
    Lenses.literal_to_string,
    Lenses.as_dom,
    custom_lens("secondary"),
    # Lenses.at_css("relationship[type=secondary]"),
    # Lenses.load_model(TestRelated)
    ]
  # def self.generated_feature_methods
  # end
  # has_one :primary
end

