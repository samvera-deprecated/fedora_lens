describe FedoraRelations do
  class TestClass
    include FedoraRelations
    attribute :title, [RDF::DC.title]
    attribute :xml_title, [RDF::DC.title]
  end

  subject { TestClass.new }

  describe ".find" do
    it "finds by a fedora path" do
      TestClass.find('/rest/ee/89/7e/53/ee897e53-7953-4208-bee7-08c76379fce8').content eq "some content"
    end
  end

  describe ".attribute" do
    it "makes a setter/getter" do
      subject.title = "foo"
      expect(subject.title).to eq "foo"
    end

    it "loads from rdf" do
    end

    it "mixes rdf and xml" do
    end
  end
end
