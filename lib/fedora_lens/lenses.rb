module FedoraLens
  module Lenses
    class << self
      def single
        {
          get: :first.to_proc,
          put: lambda {|source, value| source[0] = value; source}
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
          get: lambda do |uri_and_graph|
            uri, graph = uri_and_graph
            graph.query([uri, predicate, nil]).map{|s| s.object.value}
          end
          # put: lambda {|doc, value| doc.at_css(selector).content = value; doc}
        }
      end

      def compose(a, b)
      end

      def concat(a, b)
      end
    end
  end
end
