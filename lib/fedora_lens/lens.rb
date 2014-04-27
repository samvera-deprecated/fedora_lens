require 'active_support/core_ext/hash'

module FedoraLens
  class Lens
    def get(source)
      raise NotImplementedError.new
    end
    def put(source, value)
      raise NotImplementedError.new
    end
    def create(value)
      raise NotImplementedError.new
    end
  end
end
