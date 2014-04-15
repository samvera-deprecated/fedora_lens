require 'spec_helper'

describe FedoraLens do
  include ActiveModel::Lint::Tests

  class TestClass
    include FedoraLens
    attribute :title, [RDF::DC11.title, Lenses.single, Lenses.literal_to_string]
    attribute :size, [RDF::DC11.subject, Lenses.single, Lenses.literal_to_string]
    # attribute :xml_title, [RDF::DC11.title, Lenses.single]
  end

  # for ActiveModel::Lint::Tests
  def setup
    @model = TestClass.new
  end

  subject { TestClass.new }

  # before do
  #   require 'logger'
  #   Ldp.logger = Logger.new(STDOUT).tap do |l|
  #     l.level = Logger::DEBUG
  #   end
  # end

  describe ".find" do
    context "when the object doesn't exist" do
      it "should raise an error" do
        expect{ TestClass.find('bahvejlavawwv') }.to raise_error Ldp::NotFound
      end
    end

    context "when the object exists" do
      let(:existing) { TestClass.create(title: "created resource") }
      subject { TestClass.find(existing.id) }
      it { should be_kind_of TestClass }
      its(:id) { should eq existing.id }
    end
  end

  describe ".delete" do
    subject { TestClass.create(title: "created resource") }

    it "should be deleted" do
      subject.delete
      expect{ TestClass.find(subject.id) }.to raise_error Ldp::NotFound
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

  describe "#id" do
    it "should not have 'fedora' in the id" do
      m = TestClass.new('http://localhost:8983/fedora/rest/41/0d/6b/47/410d6b47-ce9c-4fa0-91e2-d62765667c52')
      expect(m.id).to eq '/41/0d/6b/47/410d6b47-ce9c-4fa0-91e2-d62765667c52'
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

    context "with a supplied id" do
      subject { TestClass.new(TestClass.id_to_uri('foobar')) }

      it "saves with that id" do
        expect(subject.new_record?).to be_true
        expect(subject.save).to be_true
        expect(subject.new_record?).to be_false
      end

    end

  end

  describe ".attribute" do
    it "makes a setter/getter" do
      subject.title = "foo"
      subject.size = "bar"
      expect(subject.title).to eq "foo"
      expect(subject.size).to eq "bar"
    end

    it "should return nil if it hasn't been set" do
      expect(subject.title).to be_nil
    end

    it "has a [] setter/getter" do
      subject[:title] = 'foo'
      expect(subject[:title]).to eq 'foo'
    end

    it "loads from rdf" do
    end

    it "mixes rdf and xml" do
    end

    context "that are inherited" do
      class TestSubclass < TestClass
        attribute :description, [RDF::DC11.description, Lenses.single, Lenses.literal_to_string]
      end

      subject { TestSubclass.new }

      it "should have accessor methods defined by the parent" do
        subject.title = "foo"
        subject.description = "bar"
        expect(subject.title).to eq "foo"
        expect(subject.description).to eq "bar"
      end

      context "a sibling class" do
        class TestAnotherSubclass < TestClass
        end

        subject { TestAnotherSubclass }

        it "instances should not have accessor methods defined by the other sibling" do
          expect { subject.new.description }.to raise_error NoMethodError
        end

        it "should not have attribute lenses defined by the other sibling" do
          expect(TestAnotherSubclass.attributes_as_lenses.keys).to_not include "description"
        end
      end
    end
  end
end
