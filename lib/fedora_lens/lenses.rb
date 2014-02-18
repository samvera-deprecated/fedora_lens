module FedoraLens
  module Lenses
    class << self
      def single
        {
          get: :first.to_proc,
          put: lambda {|source, value| source[0] = value; source}
        }
      end

      def literal_to_string
        {
          get: :to_s.to_proc,
          put: lambda do |source, value|
            RDF::Literal.new(value, language: source.language, datatype: source.datatype)
          end
        }
      end

      def hash_update
        {
          get: lambda {|hash| hash[key]},
          put: lambda {|hash, pair| hash.merge(pair[0] => pair[1])}
        }
      end

      def orm_to_hash(name_to_lens)
        {
          get: lambda do |orm|
            name_to_lens.reduce({}) do |hash, pair|
              key, lens = pair
              hash.merge(key => lens[:get].call(orm))
            end
          end,
          put: lambda do |orm, hash|
            name_to_lens.each do |pair|
              key, lens = pair
              lens[:put].call(orm, hash[key])
            end
            orm
          end
        }
      end

      def as_dom
        {
          # TODO figure out a memoizing strategy so we don't parse multiple times
          get: lambda {|xml| puts "parsing..."; Nokogiri::XML(xml)},
          put: lambda {|doc, value| value.to_xml}
        }
      end

      def at_css(selector)
        {
          get: lambda {|doc| doc.at_css(selector).content},
          put: lambda {|doc, value| doc.at_css(selector).content = value; doc}
        }
      end

      def get_predicate(predicate)
        {
          get: lambda do |orm|
            orm.value(predicate)
          end,
          put: lambda do |orm, values|
            orm.graph.delete([orm.resource.subject_uri, predicate, nil])
            values.each do |value|
              orm.graph.insert([orm.resource.subject_uri, predicate, value])
            end
            orm
          end
        }
      end

      def compose(outer, inner)
        {
          get: lambda do |source|
            inner[:get].call(outer[:get].call(source))
          end,
          put: lambda do |source, value|
            outer[:put].call(source, inner[:put].call(outer[:get].call(source), value))
          end
        }
      end

      def concat(first, second)
      end
    end
  end
end
