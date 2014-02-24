require 'active_support/core_ext/hash'

module FedoraLens
  class Lens < ActiveSupport::HashWithIndifferentAccess
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
end
