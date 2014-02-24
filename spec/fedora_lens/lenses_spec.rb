require './spec/minitest_helper'
require 'fedora_lens/lens_tests'

module FedoraLens
  describe Lenses do
    extend LensTests

    describe ".single" do
      it "gets the first item" do
        Lenses.single.get([:first, :second]).must_equal :first
      end
      it "sets the first item" do
        Lenses.single.put([:first, :second], :changed).must_equal [:changed, :second]
      end
      it "creates an item in an array" do
        Lenses.single.create(:value).must_equal [:value]
      end
      test_lens Lenses.single, [], :foo
      test_lens Lenses.single, [:one], :foo
      test_lens Lenses.single, [:one, :two], :foo
    end

    describe ".as_dom" do
      it "converts xml to a Nokogiri::XML::Document" do
        xml = "<foo><bar>content</bar></foo>"
        Lenses.as_dom.get(xml).to_xml.must_equal Nokogiri::XML(xml).to_xml
      end
      it "converts a modified Nokogiri::XML::Document back to xml" do
        xml = "<foo><bar>content</bar></foo>"
        modified = Nokogiri::XML("<foo><bar>changed</bar></foo>")
        Lenses.as_dom.put(xml, modified.dup).must_equal modified.to_xml
      end
      it "creates a new string of xml" do
        value = Nokogiri::XML("<foo><bar>created</bar></foo>")
        Lenses.as_dom.create(value).must_equal value.to_xml
      end
      test_lens(Lenses.as_dom,
        Nokogiri::XML("<foo><bar>content</bar></foo>").to_xml,
        Nokogiri::XML("<foo><bar>new content</bar></foo>")){|v| v.to_s}
    end

    describe ".at_css" do
      it "gets the content at the css selector" do
        dom = Nokogiri::XML("<foo><bar>content</bar></foo>")
        Lenses.at_css('foo bar').get(dom).must_equal 'content'
      end
      it "sets the first item" do
        dom = Nokogiri::XML("<foo><bar>content</bar></foo>")
        expected = Nokogiri::XML("<foo><bar>changed</bar></foo>")
        Lenses.at_css('foo bar').put(dom, :changed).to_xml.must_equal expected.to_xml
      end
      test_lens_get_put(Lenses.at_css("foo bar"), Nokogiri::XML("<foo><bar>content</bar></foo>"))
      test_lens_put_get(Lenses.at_css("foo bar"),
                        Nokogiri::XML("<foo><bar>content</bar></foo>"),
                        "new content")
    end

    describe ".get_predicate" do
      let(:orm) do
        graph = RDF::Graph.new
        orm = Ldp::Orm.new(Ldp::Resource.new(nil, '', graph))
        orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, "title"])
        orm
      end
      it "converts an Ldp::Orm to the value of the specified predicate" do
        Lenses.get_predicate(RDF::DC11.title).get(orm).first.must_equal RDF::Literal.new("title")
      end
      it "sets the value of an Ldp::Orm for the specified predicate" do
        Lenses.get_predicate(RDF::DC11.title).put(orm, [RDF::Literal.new("new")]).value(RDF::DC11.title).first.must_equal RDF::Literal.new("new")
      end
      it "creates a new Ldp::Orm with the value for a specified predicate" do
        converted = Lenses.get_predicate(RDF::DC11.title).create([RDF::Literal.new("title")])
        converted.graph.dump(:ttl).must_equal orm.graph.dump(:ttl)
      end
      graph = RDF::Graph.new
      orm = Ldp::Orm.new(Ldp::Resource.new(nil, '', graph))
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
