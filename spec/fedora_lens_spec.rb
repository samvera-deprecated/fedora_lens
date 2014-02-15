require './spec/minitest_helper'

describe FedoraLens do
  include ActiveModel::Lint::Tests

  class TestClass
    include FedoraLens
    attribute :title, [RDF::DC11.title, Lenses.single]
    attribute :xml_title, [RDF::DC11.title, Lenses.single]
  end

  # for ActiveModel::Lint::Tests
  def setup
    @model = TestClass.new
  end

  subject { TestClass.new }

  describe ".find" do
    it "finds by a fedora path" do
      # TestClass.find('/rest/ee/89/7e/53/ee897e53-7953-4208-bee7-08c76379fce8')
      a = TestClass.find('/rest/node/to/update')
      a.title.must_equal 'some-resource-title'
    end
  end

  describe ".attribute" do
    it "makes a setter/getter" do
      subject.title = "foo"
      subject.title.must_equal "foo"
    end

    it "loads from rdf" do
    end

    it "mixes rdf and xml" do
    end
  end
end
