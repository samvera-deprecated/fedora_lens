require 'spec_helper'
require 'fedora_lens/lens_tests'

module FedoraLens
  describe Lenses do
    include LensTests

    describe ".first" do
      it "gets the first item" do
        Lenses.first.get([:first, :second]).should eq :first
        Lenses.single.get([:first, :second]).should eq :first
      end
      it "sets the first item" do
        Lenses.first.put([:first, :second], :changed).should eq [:changed, :second]
        Lenses.single.put([:first, :second], :changed).should eq [:changed, :second]
      end
      it "creates an item in an array" do
        Lenses.first.create(:value).should eq [:value]
        Lenses.single.create(:value).should eq [:value]
      end
      it "obeys lens laws" do
        check_laws Lenses.first, [], :foo
        check_laws Lenses.first, [:one], :foo
        check_laws Lenses.first, [:one, :two], :foo
        check_laws Lenses.single, [], :foo
        check_laws Lenses.single, [:one], :foo
        check_laws Lenses.single, [:one, :two], :foo
      end
    end

    describe ".literal_to_string" do
      let(:lens) { Lenses.literal_to_string }
      let(:source) { RDF::Literal.new('foo') }
      let(:value) { 'foo' }

      it "obeys lens laws" do
        check_laws lens, source, value
      end

      describe "#get" do
        it "casts them to string" do
          expect(lens.get(source)).to eq value
        end
      end

      describe "#put" do
        it "casts them to string" do
          expect(lens.put(nil, value)).to eq source
        end
      end
    end

    describe ".literals_to_strings" do
      let(:lens) { Lenses.literals_to_strings }
      let(:input) { [RDF::Literal.new('foo'), RDF::Literal.new('bar')] }
      subject { lens.get(input) }

      it "obeys lens laws" do
        check_laws lens, input, ['foo', 'bar']
      end

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

      it "obeys lens laws" do
        check_laws lens, original, ['/id/123', '/id/321']
      end

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

    describe ".orm_to_hash" do
      let(:lens) do
        Lenses.orm_to_hash(title: Lenses.get_predicate(RDF::DC11.title),
                           description: Lenses.get_predicate(RDF::DC11.description))
      end
      let(:mock_conn) { double }
      let(:resource) { Ldp::Resource::RdfSource.new(mock_conn, '', RDF::Graph.new) }
      let(:orm) { Ldp::Orm.new(resource) }
      before { resource.stub(new?: true) }

      it "reads from an orm" do
        orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "old title"])
        expect(lens.get(orm)).to eq(title: [RDF::Literal.new("old title")], description: [])
      end

      it "updates values in an orm" do
        orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "old title"])
        updated = lens.put(orm, title: "new title", description: "new desc")
        expect(updated.value(RDF::DC11.title)).to eq [RDF::Literal.new("new title")]
        expect(updated.value(RDF::DC11.description)).to eq [RDF::Literal.new("new desc")]
      end

      it "treats missing keys as nil" do
        orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "old title"])
        updated = lens.put(orm, {})
        expect(updated.value(RDF::DC11.title)).to eq []
      end

      it "raises an error for unexpected keys" do
        expect{lens.put(orm, unexpected: :key)}.to raise_exception ArgumentError
        expect{lens.create(unexpected: :key)}.to raise_exception ArgumentError
      end

      it "obeys lens laws" do
        check_laws lens, orm, {title: [RDF::Literal.new('new title')], description: []}
        orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "old title"])
        check_laws lens, orm, {title: [RDF::Literal.new('new title')], description: []}
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
      it "obeys lens laws" do
        check_laws(Lenses.as_dom,
                   Nokogiri::XML("<foo><bar>content</bar></foo>").to_xml,
                   Nokogiri::XML("<foo><bar>new content</bar></foo>")){|v| v.to_s}
      end
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
      it "obeys lens laws" do
        check_get_put(Lenses.at_css("foo bar"), Nokogiri::XML("<foo><bar>content</bar></foo>"))
        check_put_get(Lenses.at_css("foo bar"),
                      Nokogiri::XML("<foo><bar>content</bar></foo>"),
                      "new content")
      end
    end

    describe ".get_predicate" do
      let(:orm) do
        Ldp::Orm.new(resource).tap do |orm|
          orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "new title"])
        end
      end

      let(:resource) { Ldp::Resource::RdfSource.new(mock_conn, '', RDF::Graph.new) } 
      let(:mock_conn) { double }
      before { resource.stub(new?: true) }
      subject { Lenses.get_predicate(RDF::DC11.title) }

      let(:value) { [RDF::Literal.new("new title")] }

      it "converts an Ldp::Orm to the value of the specified predicate" do
        subject.get(orm).first.should eq value.first 
      end

      it "gets an empty set" do
        Lenses.get_predicate(RDF::DC11.description).get(orm).should eq []
      end

      it "is well-behaved (PutGet: get(put(source, value)) == value)" do
        converted = subject.get(subject.put(orm, value))
        expect(converted).to eq value
      end

      it "sets the value of an Ldp::Orm for the specified predicate" do
        subject.put(orm, [RDF::Literal.new("new")]).value(RDF::DC11.title).first.should eq RDF::Literal.new("new")
      end

      it "is well-behaved (GetPut: put(source, get(source)) == source)" do
        converted = subject.put(orm, subject.get(orm))
        expect(converted).to eq orm
      end

      it "creates a new Ldp::Orm with the value for a specified predicate" do
        converted = subject.create(value)
        converted.graph.should eq orm.graph
      end

      it "is well-behaved (CreateGet: get(create(value)) == value)" do
        created = subject.get(subject.create(value))
        expect(created).to eq value
      end
    end

    describe ".compose" do
      let(:lens) { Lenses.compose(Lenses.first, Lenses.literal_to_string) }
      it "obeys lens laws" do
        check_laws lens, [], 'foo'
        check_laws lens, [RDF::Literal.new('one')], 'foo'
        check_laws lens, [RDF::Literal.new('one'), RDF::Literal.new('two')], 'foo'
      end
    end
  end
end
