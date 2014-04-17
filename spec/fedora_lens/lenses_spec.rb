require 'spec_helper'
require 'fedora_lens/lens_tests'

module FedoraLens
  describe Lenses do
    extend LensTests

    describe ".single" do
      it "gets the first item" do
        Lenses.single.get([:first, :second]).should eq :first
      end
      it "sets the first item" do
        Lenses.single.put([:first, :second], :changed).should eq [:changed, :second]
      end
      it "creates an item in an array" do
        Lenses.single.create(:value).should eq [:value]
      end
      test_lens Lenses.single, [], :foo
      test_lens Lenses.single, [:one], :foo
      test_lens Lenses.single, [:one, :two], :foo
    end

    describe ".literals_to_strings" do
      let(:lens) { Lenses.literals_to_strings }

      subject { lens.get(input) }

      describe "#get" do
        let(:input) { [RDF::Literal.new('foo'), RDF::Literal.new('bar')] }
        it "casts them to string" do
          expect(subject).to eq ['foo', 'bar']
        end

        context "with an empty result" do
          let(:input) { [] }
          it "casts them to string" do
            expect(subject).to eq []
          end
        end
      end

      describe "#put" do
        subject { lens.put([RDF::Literal.new("foo"), RDF::Literal.new("bar")], input) }
        let(:input) { ['quack', 'quix'] }
        it "overwrites the items" do
          expect(subject).to eq [RDF::Literal.new("quack"), RDF::Literal.new("quix")]
        end

        context "with an empty set" do
        let(:input) { nil }
          it "casts them to string" do
            expect(subject).to eq []
             
          end
        end
      end
    end

    describe ".uris_to_ids" do
      let(:lens) { Lenses.uris_to_ids }

      let(:original) { [RDF::URI.new(HOST + '/id/123'), RDF::URI.new(HOST + '/id/321')] }

      describe "#get" do
        subject { lens.get(input) }

        context "with exiting content" do
          let(:input) { original  }
          it "casts them to string" do
            expect(subject).to eq ['/id/123', '/id/321']
          end
        end

        context "with an empty result" do
          let(:input) { [] }
          it "casts them to string" do
            expect(subject).to eq []
          end
        end
      end

      describe "#put" do
        subject { lens.put(original, input) }

        context "with new values " do
          let(:input) { ['/id/777', '/id/888'] }
          it "overwrites the items" do
            expect(subject).to eq [RDF::URI.new(HOST + '/id/777'), RDF::URI.new(HOST + '/id/888')]
          end
        end

        context "with an empty set" do
          let(:input) { [nil] }
          it "casts them to string" do
            expect(subject).to eq []
             
          end
        end
      end
    end

    describe ".as_dom" do
      it "converts xml to a Nokogiri::XML::Document" do
        xml = "<foo><bar>content</bar></foo>"
        Lenses.as_dom.get(xml).to_xml.should eq Nokogiri::XML(xml).to_xml
      end
      it "converts a modified Nokogiri::XML::Document back to xml" do
        xml = "<foo><bar>content</bar></foo>"
        modified = Nokogiri::XML("<foo><bar>changed</bar></foo>")
        Lenses.as_dom.put(xml, modified.dup).should eq modified.to_xml
      end
      it "creates a new string of xml" do
        value = Nokogiri::XML("<foo><bar>created</bar></foo>")
        Lenses.as_dom.create(value).should eq value.to_xml
      end
      test_lens(Lenses.as_dom,
        Nokogiri::XML("<foo><bar>content</bar></foo>").to_xml,
        Nokogiri::XML("<foo><bar>new content</bar></foo>")){|v| v.to_s}
    end

    describe ".at_css" do
      it "gets the content at the css selector" do
        dom = Nokogiri::XML("<foo><bar>content</bar></foo>")
        Lenses.at_css('foo bar').get(dom).should eq 'content'
      end
      it "sets the first item" do
        dom = Nokogiri::XML("<foo><bar>content</bar></foo>")
        expected = Nokogiri::XML("<foo><bar>changed</bar></foo>")
        Lenses.at_css('foo bar').put(dom, :changed).to_xml.should eq expected.to_xml
      end
      test_lens_get_put(Lenses.at_css("foo bar"), Nokogiri::XML("<foo><bar>content</bar></foo>"))
      test_lens_put_get(Lenses.at_css("foo bar"),
                        Nokogiri::XML("<foo><bar>content</bar></foo>"),
                        "new content")
    end

    describe ".get_predicate" do
      let(:orm) do
        graph = RDF::Graph.new
        orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(nil, '', graph))
        orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "title"])
        orm
      end
      it "converts an Ldp::Orm to the value of the specified predicate" do
        Lenses.get_predicate(RDF::DC11.title).get(orm).first.should eq RDF::Literal.new("title")
      end
      it "gets an empty set" do
        Lenses.get_predicate(RDF::DC11.description).get(orm).should eq []
      end
      it "sets the value of an Ldp::Orm for the specified predicate" do
        Lenses.get_predicate(RDF::DC11.title).put(orm, [RDF::Literal.new("new")]).value(RDF::DC11.title).first.should eq RDF::Literal.new("new")
      end
      it "creates a new Ldp::Orm with the value for a specified predicate" do
        converted = Lenses.get_predicate(RDF::DC11.title).create([RDF::Literal.new("title")])
        converted.graph.dump(:ttl).should eq orm.graph.dump(:ttl)
      end
      graph = RDF::Graph.new
      orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(nil, '', graph))
      orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "title"])
      test_lens(Lenses.get_predicate(RDF::DC11.title), orm, [RDF::Literal.new("new title")]) do |v|
        if v.is_a? Ldp::Orm
          v.value(RDF::DC11.title)
        else
          v
        end
      end
    end
  end
end
