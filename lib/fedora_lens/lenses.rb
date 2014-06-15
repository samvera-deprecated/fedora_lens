require 'fedora_lens/lens'

module FedoraLens
  module Lenses
    # We would like to use lenses like this: Lenses.at_css.get(...)
    # Using a simple hash is gross because calls are like this: Lenses.at_css[:get].call(...)
    # If we use a Module, we can't pass in parameters to build a more specific lens like
    # in the case of the at_css lens.
    # If we use a class, we need to call it like this: Lenses::AtCss.new('path').get(...)
    # that's a lot of ".new" that just becomes line noise
    # Classes don't seem to close over their environment as a function would (not sure why...)
    # so we can create anonymous classes with functions
    # Instead, we're just adding the helper functions to a simple hash.

    class << self
      class First < Lens
        def get(source)
          source.first
        end
        def put(source, value)
          source[0] = value
          source
        end
        def create(value)
          [value]
        end
      end
      def first
        First.new
      end
      def single
        $stderr.puts "DEPRECATION WARNING: FedoraLens::Lenses::single: use ::first instead (it works exactly the same, will be removed in 1.0)"
        First.new
      end

      class LiteralToString < Lens
        def get(source)
          source.to_s
        end
        def put(source, value)
          if source.is_a?(RDF::Literal)
            RDF::Literal.new(value, language: source.language, datatype: source.datatype)
          else
            create(value)
          end
        end
        def create(value)
          RDF::Literal.new(value)
        end
      end
      def literal_to_string
        LiteralToString.new
      end

      class LiteralsToStrings < Lens
        def get(sources)
          sources.map(&:to_s)
        end
        def put(sources, values)
          create(values)
        end
        def create(values)
          Array(values).map do |value|
            RDF::Literal.new(value)
          end
        end
      end
      def literals_to_strings
        LiteralsToStrings.new
      end

      class UrisToIds < Lens
        def get(sources)
          sources.map { |uri| URI.parse(uri).to_s.sub(HOST, '') }
        end
        def put(sources, values)
          create(values)
        end
        def create(values)
          Array(values).compact.map do |value|
            RDF::URI.new(HOST + value)
          end
        end
      end
      def uris_to_ids
        UrisToIds.new
      end

      class OrmToHash < Lens
        def initialize(name_to_lens)
          @name_to_lens = name_to_lens
          super
        end
        def get(orm)
          @name_to_lens.reduce({}) do |hash, (key, lens)|
            hash.merge(key => lens.get(orm))
          end
        end
        def put(orm, hash)
          unexpected = hash.keys - @name_to_lens.keys
          raise ArgumentError.new("Unexpected keys for put: #{unexpected}") if unexpected.present?
          @name_to_lens.each do |(key, lens)|
            lens.put(orm, hash[key])
          end
          orm
        end
        def create(hash)
          orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(FedoraLens.connection, '', RDF::Graph.new))
          put(orm, hash)
        end
      end
      def orm_to_hash(name_to_lens)
        OrmToHash.new(name_to_lens)
      end

      class AsDom < Lens
        def get(xml)
          Nokogiri::XML(xml)
        end
        def put(xml, dom)
          create(dom)
        end
        def create(dom)
          dom.to_xml
        end
      end
      def as_dom
        AsDom.new
      end

      class AtCss
        def initialize(selector)
          @selector = selector
          super()
        end
        def get(doc)
          doc.at_css(@selector).content
        end
        def put(doc, value)
          doc.at_css(@selector).content = value
          doc
        end
      end
      def at_css(selector)
        AtCss.new(selector)
      end

      class GetPredicate < Lens
        # @param [RDF::URI] predicate
        # @param [Hash] opts
        # @option opts [Proc] :select a proc that takes the object and returns 
        #                             true if it should be included in this subset
        #                             of the predicates.  Used for storing
        #                             different classes of objects under different
        #                             attribute names even though they all use the
        #                             same predicate.
        def initialize(predicate, opts = {})
          @predicate = predicate
          @opts = opts
          super
        end
        def empty_property(graph, rdf_subject, predicate, should_delete)
          if should_delete
            graph.query([rdf_subject, predicate, nil]).each_statement do |statement|
              if should_delete.call(statement.object)
                graph.delete(statement)
              end
            end
          else
            graph.delete([rdf_subject, predicate, nil])
          end
        end
        def get(orm)
          values = orm.value(@predicate)
          if @opts[:select]
            values.select { |val| @opts[:select].call(val) }
          else
            values
          end
        end
        def put(orm, values)
          empty_property(orm.graph, orm.resource.subject_uri, @predicate, @opts[:select])
          Array(values).each do |value|
            orm.graph.insert([orm.resource.subject_uri, @predicate, value])
          end
          orm
        end
        def create(values)
          orm = Ldp::Orm.new(Ldp::Resource::RdfSource.new(FedoraLens.connection, '', RDF::Graph.new))
          put(orm, values)
        end
      end
      def get_predicate(predicate, opts = {})
        GetPredicate.new(predicate, opts)
      end

      class Compose < Lens
        def initialize(outer, inner)
          @outer = outer
          @inner = inner
          super
        end
        def get(source)
          @inner.get(@outer.get(source))
        end
        def put(source, value)
          @outer.put(source, @inner.put(@outer.get(source), value))
        end
        def create(value)
          @outer.create(@inner.create(value))
        end
      end
      def compose(outer, inner)
        Compose.new(outer, inner)
      end
    end
  end
end
