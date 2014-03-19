require './spec/minitest_helper'

describe FedoraLens do
  include ActiveModel::Lint::Tests

  class TestClass
    include FedoraLens
    attribute :title, [RDF::DC11.title, Lenses.single, Lenses.literal_to_string]
    # attribute :xml_title, [RDF::DC11.title, Lenses.single]
  end

  # for ActiveModel::Lint::Tests
  def setup
    @model = TestClass.new
  end

  subject { TestClass.new }

  describe ".create" do
    it "creates a resource" do
      m = TestClass.create(title: "created resource")
      TestClass.find(m.id).title.must_equal "created resource"
    end
  end

  describe ".save" do
    it "saves a new resource" do
      m = TestClass.new(title: "created resource")
      m.save
      TestClass.find(m.id).title.must_equal "created resource"
    end

    it "saves an updated resource" do
      m = TestClass.create(title: "created resource")
      m.reload
      m.title = "changed title"
      m.save
      TestClass.find(m.id).title.must_equal "changed title"
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
