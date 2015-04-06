require 'active_support/core_ext/hash'

module FedoraLens
  class Lens
    attr_reader(:options)

    def initialize(*options)
      @options = options
    end

    def get(source)
      raise NotImplementedError.new
    end

    def put(source, value)
      raise NotImplementedError.new
    end

    def create(value)
      raise NotImplementedError.new
    end

    def ==(other_lens)
      self.class == other_lens.class && options == other_lens.options
    end
  end
end
