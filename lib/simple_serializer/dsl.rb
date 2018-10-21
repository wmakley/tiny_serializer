# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

class SimpleSerializer
  # The SimpleSerializer class macros.
  module DSL
    # Get all the sub-record attribute definitions (created by #belongs_to,
    # #has_one, etc.)
    def sub_records
      @sub_records ||=
        if superclass.respond_to?(:sub_records)
          superclass.sub_records.dup
        else
          []
        end
    end

    # Get only the names of the sub-record attribute definitions (created by
    # #belongs_to, #has_one, etc.)
    def sub_record_names
      sub_records.map(&:first)
    end

    # Get all the collection definitions (created by #has_many).
    def collections
      @collections ||=
        if superclass.respond_to?(:collections)
          superclass.collections.dup
        else
          []
        end
    end

    # Get only the names of the collections definitions (created by #has_many).
    def collection_names
      collections.map(&:first)
    end

    # Definite a new attribute to serialize. The value to serialize is retrieved
    # in one of two ways:
    #
    # 1. *Default:* Calls #public_send(name) on SimpleSerializer#object.
    # 2. *Block:* The return value of the block is used.
    #
    # name::
    #   The name of the attribute
    # key::
    #   Optional. Defaults to *name*. The Hash key to assign the attribute's
    #   value to.
    # is_id::
    #   Optional. Whether the attribute is a database ID. Guessed from its name
    #   by default.
    #
    def attribute(name, key: name, is_id: _is_id?(name), &block)
      _initialize_attributes
      name = name.to_sym
      attribute = [name, key, is_id, block]
      @attributes << attribute
      return attribute
    end

    # Define multiple attributes at once, using the defaults.
    def attributes(*names)
      if names && !names.empty?
        names.each do |name|
          attribute(name)
        end
      else
        _initialize_attributes
      end
      return @attributes
    end

    # Get the names of all attributes defined using #attribute.
    def attribute_names
      attributes.map(&:first)
    end

    # Alias of #sub_record
    def has_one(association_name, key: association_name, serializer: nil, &block)
      sub_record(association_name, key: key, serializer: serializer, &block)
    end

    # Alias of #sub_record
    def belongs_to(association_name, key: association_name, serializer: nil, &block)
      sub_record(association_name, key: key, serializer: serializer, &block)
    end

    # Define a serializer to use for a sub-object of SimpleSerializer#object.
    # <b>If given a block:</b> Will use the block to retrieve the
    # object, instead of public_send(name).
    #
    # name::
    #   The method name of the sub-object.
    # serializer::
    #   Optional. The serializer class to use. Inferred from name if blank.
    #   Must be a subclass of SimpleSerializer.
    # key::
    #   Optional. Defaults to *name*. The Hash key to assign the sub-record's
    #   JSON to.
    #
    def sub_record(name, key: name, serializer: nil, &block)
      if serializer.nil?
        serializer = "#{name.to_s.camelize}Serializer".constantize
      elsif !_is_serializer?(serializer)
        raise ArgumentError, "#{serializer} does not appear to be a SimpleSerializer"
      end

      sub_records << [name, key, serializer, block]
    end

    # Alias of #collection
    def has_many(name, key: name, serializer: nil, &block)
      collection(name, key: key, serializer: serializer, &block)
    end

    # Define a serializer to use to serialize a collection of objects
    # as an Array. Will call #public_send(name) on SimpleSerializer#object
    # to get the items in the collection, or use the return value of
    # the block.
    #
    # name::
    #   The name of the collection.
    # key::
    #   Optional. Defaults to *name*. The Hash key to assign the serialized
    #   Array to.
    # serializer::
    #   Optional, inferred from *collection_name*. The serializer class to use
    #   to serialize each item in the collection. Must be a subclass of
    #   SimpleSerializer.
    #
    def collection(name, key: name, serializer: nil, &block)
      if serializer.nil?
        serializer = "#{name.to_s.singularize.camelize}Serializer".constantize
      elsif !_is_serializer?(serializer)
        raise ArgumentError, "#{serializer} does not appear to be a SimpleSerializer"
      end
      collections << [name, key, serializer, block]
    end

    # Private method to initialize inherited attributes.
    def _initialize_attributes # :nodoc:
      @attributes ||=
        if superclass.respond_to?(:attributes)
          superclass.attributes.dup
        else
          []
        end
    end

    # Private method to check if an attribute name is an ID.
    def _is_id?(name) # :nodoc:
      name == :id || name.to_s.end_with?("_id")
    end

    # Private method to check if a class is a SimpleSerializer subclass
    def _is_serializer?(klass)
      klass <= SimpleSerializer
    end
  end
end
