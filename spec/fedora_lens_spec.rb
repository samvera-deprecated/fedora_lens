require 'spec_helper'

describe FedoraLens do
  include ActiveModel::Lint::Tests

  # for ActiveModel::Lint::Tests
  def setup
    @model = TestClass.new
  end


  # before do
  #   require 'logger'
  #   Ldp.logger = Logger.new(STDOUT).tap do |l|
  #     l.level = Logger::DEBUG
  #   end
  # end


  context "with a simple class" do
    before do
      class TestClass
        include FedoraLens
        attribute :title, [RDF::DC11.title, Lenses.single, Lenses.literal_to_string]
      end
    end

    after do
      Object.send(:remove_const, :TestClass)
    end

    subject { TestClass.new }

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

        it "should have the same id" do
          expect(subject.id).to eq existing.id
        end
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
        m = TestClass.new(FedoraLens.host + '/41/0d/6b/47/410d6b47-ce9c-4fa0-91e2-d62765667c52')
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
        m.save!
        TestClass.find(m.id).title.should eq "changed title"
      end

      context "with a supplied id" do
        subject { TestClass.new(TestClass.id_to_uri('foobar')) }

        after { subject.delete }

        it "saves with that id" do
          expect(subject.new_record?).to be true
          expect(subject.save).to be true
          expect(subject.new_record?).to be false
        end

      end
    end

    describe "id_to_uri" do
      subject { TestClass.id_to_uri(id) }
      context "no base_path set" do
        context "without a leading slash" do
          let(:id) { 'test' }
          it { should eq FedoraLens.host + '/test' }
        end
        context "with a leading slash" do
          let(:id) { '/test' }
          it { should eq FedoraLens.host + '/test' }
        end
      end

      context "with base_path set" do
        before do
          @original_base = FedoraLens.base_path
          FedoraLens.base_path = '/test'
        end

        after { FedoraLens.base_path = @original_base }

        context "without a leading slash" do
          let(:id) { 'test-me' }
          it { should eq FedoraLens.host + '/test/test-me' }
        end
        context "with a leading slash" do
          let(:id) { '/test-me' }
          it { should eq FedoraLens.host + '/test/test-me' }
        end
        context "within the base path" do
          let(:id) { '/test/test-me' }
          it { should eq FedoraLens.host + '/test/test-me' }
        end
      end
    end

    describe "uri_to_id" do
      subject { TestClass.uri_to_id(uri) }
      context "no base_path set" do

        context "at the base level" do
          let(:uri) { "#{FedoraLens.host}/test" }
          it { should eq '/test' }
        end
        context "at the second level" do
          let(:uri) { "#{FedoraLens.host}/test/foo" }
          it { should eq '/test/foo' }
        end
      end

      context "with base_path set" do
        before do
          @original_base = FedoraLens.base_path
          FedoraLens.base_path = '/test'
        end

        after { FedoraLens.base_path = @original_base }

        context "at the base level" do
          let(:uri) { "#{FedoraLens.host}/test/foo" }
          it { should eq '/foo' }
        end
        context "at the second level" do
          let(:uri) { "#{FedoraLens.host}/test/foo/bar" }
          it { should eq '/foo/bar' }
        end
      end
    end
  end

  context "with a class that has many attributes" do
    before do
      class TestClass
        include FedoraLens
        attribute :title, [RDF::DC11.title, Lenses.single, Lenses.literal_to_string]
        attribute :subject, [RDF::DC11.subject, Lenses.single, Lenses.literal_to_string]
      end
    end

    after do
      Object.send(:remove_const, :TestClass)
    end

    subject { TestClass.new }

    describe ".attribute" do
      it "makes a setter/getter" do
        subject.title = "foo"
        subject.subject = "bar"
        expect(subject.title).to eq "foo"
        expect(subject.subject).to eq "bar"
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
        before do
          class TestClass2
            include FedoraLens

            class << self
              def only_foos
                lambda { |obj| obj == 'foo' }
              end

              def only_bars
                lambda { |obj| obj == 'bar' }
              end
            end

            attribute :subject, [Lenses.get_predicate(RDF::DC11.subject, select: only_foos), Lenses.literals_to_strings]
            attribute :subject2, [Lenses.get_predicate(RDF::DC11.subject, select: only_bars), Lenses.literals_to_strings]
          end
        end
        after do
          Object.send(:remove_const, :TestClass2)
        end

        let(:original_values) { { 'subject' => ['foo'], 'subject2' => ['bar'] } }

        subject { TestClass2.new(original_values) }
        before { subject.send(:push_attributes_to_orm) }


        it "should multiplex the separate attributes into one predicate" do
          expect(subject.orm.graph.dump(:ttl)).to eq( 
            "\n<> <http://purl.org/dc/elements/1.1/subject> \"foo\",\n" +
            "     \"bar\" .\n")
        end

        it "should demultiplex the predicate into separate attributes into one predicat" do
          expect(subject.send(:get_attributes_from_orm, subject.orm)).to eq original_values
        end
      end

      context "that are inherited" do
        before do
          class TestSubclass < TestClass
            attribute :description, [RDF::DC11.description, Lenses.single, Lenses.literal_to_string]
          end
        end
        after do
          Object.send(:remove_const, :TestSubclass)
        end

        subject { TestSubclass.new }

        it "should have accessor methods defined by the parent" do
          subject.title = "foo"
          subject.description = "bar"
          expect(subject.title).to eq "foo"
          expect(subject.description).to eq "bar"
        end

        context "a sibling class" do
          before do
            class TestAnotherSubclass < TestClass
            end
          end

          after do
            Object.send(:remove_const, :TestAnotherSubclass)
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
end
