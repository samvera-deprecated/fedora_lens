module FedoraLens
  module Lenses
    # We would like to use lenses like this: Lenses.at_css.get(...)
    # Using a simple hash is gross because calls are like this: Lenses.at_css[:get].call(...)
    # If we use a Module, we can't pass in parameters to build a more specific lens like
    # in the case of the at_css lens.
    # If we use a class, we need to call it like this: Lenses::AtCss.new('path').get(...)
    # Classes don't seem to close over their environment as a function would (not sure why...)
    # Instead, we're just adding the helper functions to a simple hash.
    module Accessors
      def get(source)
        self[:get].call(source)
      end
      def put(source, value)
        self[:put].call(source, value)
      end
      def create(value)
        self[:create].call(value)
      end
    end

    class << self
      def single
        {
          get: :first.to_proc,
          put: lambda {|source, value| source[0] = value; source},
          create: lambda {|value| [value]}
        }.extend(Accessors)
      end

      def literal_to_string
        {
          get: :to_s.to_proc,
          put: lambda do |source, value|
            RDF::Literal.new(value, language: source.language, datatype: source.datatype)
          end
        }.extend(Accessors)
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
          put: lambda {|xml, value| value.to_xml},
          create: lambda {|value| value.to_xml}
        }.extend(Accessors)
      end

      def at_css(selector)
        {
          get: lambda {|doc| doc.at_css(selector).content},
          put: lambda {|doc, value| doc.at_css(selector).content = value; doc},
          # can't do a css create because we don't know the structure
        }.extend(Accessors)
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

      def load_model(klass)
        {
          get: lambda do |id|
            klass.find(id)
          end,
          put: lambda do |id, model|
            model.save
            id
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
