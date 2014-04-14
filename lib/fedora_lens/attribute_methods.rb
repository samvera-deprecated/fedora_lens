require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute'

module FedoraLens
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    AttrNames = Module.new {
      def self.set_name_cache(name, value)
        const_name = "ATTR_#{name}"
        unless const_defined? const_name
          const_set const_name, value.dup.freeze
        end
      end
    }

    class AttributeMethodCache
      def initialize
        @module = Module.new
        @method_cache = ThreadSafe::Cache.new
      end

      def [](name)
        @method_cache.compute_if_absent(name) do
          safe_name = name.unpack('h*').first
          temp_method = "__temp__#{safe_name}"
          FedoraLens::AttributeMethods::AttrNames.set_name_cache safe_name, name
          @module.module_eval method_body(temp_method, safe_name), __FILE__, __LINE__
          @module.instance_method temp_method
        end
      end

      private
      def method_body; raise NotImplementedError; end
    end


    included do
      class_attribute :attributes_as_lenses
      self.attributes_as_lenses = {}.with_indifferent_access
      
      initialize_generated_modules
      include Read
      include Write
    end

    # Returns an array of names for the attributes available on this object.
    #
    #   class Person
    #     include FedoraLens
    #   end
    #
    #   person = Person.new
    #   person.attribute_names
    #   # => ["id", "created_at", "updated_at", "name", "age"]
    def attribute_names
      @attributes.keys
    end

    # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
    #
    #   class Person
    #     include FedoraLens
    #   end
    #
    #   person = Person.create(name: 'Francesco', age: 22)
    #   person.attributes
    #   # => {"id"=>3, "created_at"=>Sun, 21 Oct 2012 04:53:04, "updated_at"=>Sun, 21 Oct 2012 04:53:04, "name"=>"Francesco", "age"=>22}
    def attributes
      attribute_names.each_with_object({}) { |name, attrs|
        attrs[name] = read_attribute(name)
      }
    end

    module ClassMethods
      def initialize_generated_modules # :nodoc:
        @generated_attribute_methods = Module.new { extend Mutex_m }
        include @generated_attribute_methods
      end

      def attribute(name, path, options={})
        raise AttributeNotSupportedException if name.to_sym == :id
        attributes_as_lenses[name] = path.map{|s| coerce_to_lens(s)}
        generate_method(name)
        orm_to_hash = nil # force us to rebuild the aggregate_lens in case it was already built.
      end

      private
        def coerce_to_lens(path_segment)
          if path_segment.is_a? RDF::URI
            Lenses.get_predicate(path_segment)
          else
            path_segment
          end
        end

        # @param name [Symbol] name of the attribute to generate
        def generate_method(name)
          generated_attribute_methods.synchronize do
            define_attribute_methods name
          end
        end
    end
  end
end
