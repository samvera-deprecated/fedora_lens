require 'spec_helper'

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

  describe ".find" do
    context "when the object doesn't exist" do
      it "" do
        expect{ TestClass.find('bahvejlavawwv') }.to raise_error Ldp::NotFound
      end
    end
  end

  describe ".create" do
    subject { TestClass.create(attributes) }
    context "with a hash" do
      let(:attributes) { { title: "created resource" } }
      it "creates a resource" do
        expect(TestClass.find(subject.id).title).to eq "created resource"
      end
    end
    context "with nil" do
      let(:attributes) { nil }
      it "creates a resource" do
        expect(TestClass.find(subject.id)).to be_kind_of TestClass
      end
    end
  end

  describe ".save" do
    it "saves a new resource" do
      m = TestClass.new(title: "created resource")
      m.save
      TestClass.find(m.id).title.should eq "created resource"
    end

    it "saves an updated resource" do
      m = TestClass.create(title: "created resource")
      m.reload
      m.title = "changed title"
      m.save
      TestClass.find(m.id).title.should eq "changed title"
    end
  end

  describe ".attribute" do
    it "makes a setter/getter" do
      subject.title = "foo"
      subject.title.should eq "foo"
    end

    it "loads from rdf" do
    end

    it "mixes rdf and xml" do
    end
  end
end
