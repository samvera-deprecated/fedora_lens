module FedoraLens
  module LensTests
    # See page 6 of the manual for the Harmony language for a description
    # on how lenses work
    # http://www.seas.upenn.edu/~harmony/manual.pdf

    class LensLawError < StandardError
      def initialize(actual, expected)
        @actual = actual
        @expected = expected
      end
      def message(desc)
        "Lens must be well-behaved (#{desc})
expected: #{@expected.inspect}
     got: #{@actual.inspect}"
      end
    end
    class GetPutError < LensLawError
      def message
        super("GetPut: lens.put(source, lens.get(source)) == source")
      end
    end
    class PutGetError < LensLawError
      def message
        super("PutGet: lens.get(lens.put(source, value)) == value")
      end
    end
    class CreateGetError < LensLawError
      def message
        super("CreateGet: lens.get(lens.create(value)) == value")
      end
    end

    # @example testing a lens that converts xml to a dom and back
    #   check_laws(lens, Nokogiri::XML("<a/>"), Nokogiri::XML("<b/>") do |v|
    #     v.to_xml
    #   end
    # @param  [lens]
    #   the lens to test
    # @param  [value]
    #   the value to test with (when calling put)
    # @param  [source]
    #   the source document this lens operates on
    # @yield  [actual, expected]
    #   a block that returns true if the supplied values are equal
    def check_laws(lens, source, value, &block)
      if block_given?
        equality_test = block
      else
        equality_test = lambda { |a, b| a == b }
      end

      actual, expected = check_get_put(lens, source)
      raise GetPutError.new(actual, expected) unless equality_test.call(actual, expected)
      actual, expected = check_put_get(lens, source, value)
      raise PutGetError.new(actual, expected) unless equality_test.call(actual, expected)
      actual, expected = check_create_get(lens, value)
      raise CreateGetError.new(actual, expected) unless equality_test.call(actual, expected)
    end

    def check_get_put(lens, source)
      [lens.put(source, lens.get(source)), source]
    end
    def check_put_get(lens, source, value)
      [lens.get(lens.put(source, value)), value]
    end
    def check_create_get(lens, value)
      [lens.get(lens.create(value)), value]
    end
  end
end
