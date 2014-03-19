module FedoraLens
  module LensTests
    # See page 6 of the manual for the Harmony language for a description
    # on how lenses work
    # http://www.seas.upenn.edu/~harmony/manual.pdf
    # @example testing a lens that converts xml to a dom and back
    #   test_lens(lens, Nokogiri::XML("<a/>"), Nokogiri::XML("<b/>") do |v|
    #     v.to_xml
    #   end
    # @param  [lens]
    #   the lens to test
    # @param  [value]
    #   the value to test with (when calling put)
    # @param  [source]
    #   the source document this lens operates on
    # @yield  [converter]
    #   a block that converts the value from the lens to something that can be
    #   compared with #== (defaults to the identity function)
    # @yieldparam [value or source]
    #   a value that will be compared
    def test_lens(lens, source, value, &block)
      test_lens_get_put(lens, source, &block)
      test_lens_put_get(lens, source, value, &block)
      test_lens_create_get(lens, value, &block)
    end

    def test_lens_get_put(lens, source)
      it "is well-behaved (GetPut: put(source, get(source)) == source)" do
        converted = lens.put(source, lens.get(source))
        if block_given?
          yield(converted).should eq yield(source)
        else
          converted.should eq source
        end
      end
    end

    def test_lens_put_get(lens, source, value)
      it "is well-behaved (PutGet: get(put(source, value)) == value)" do
        converted = lens.get(lens.put(source, value))
        if block_given?
          yield(converted).should eq yield(value)
        else
          converted.should eq value
        end
      end
    end

    def test_lens_create_get(lens, value)
      it "is well-behaved (CreateGet: get(create(value)) == value)" do
        created = lens.get(lens.create(value))
        if block_given?
          yield(created).should eq yield(value)
        else
          created.should eq value
        end
      end
    end
  end
end
