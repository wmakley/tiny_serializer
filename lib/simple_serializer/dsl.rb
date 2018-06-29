require "active_support/core_ext/string/inflections"

class SimpleSerializer
  module DSL
    def sub_records
      @sub_records ||= []
    end

    def collections
      @collections ||= []
    end

    def attribute(name, is_id: is_id?(name), &block)
      @attributes ||= []
      name = name.to_sym
      attribute = [name, is_id, block]
      @attributes << attribute
      return attribute
    end

    def attributes(*names)
      if names && !names.empty?
        names.each do |name|
          attribute(name)
        end
      end
      return @attributes || []
    end

    def has_one(association_name, serializer: nil, record_type: nil, polymorphic: false, &block)
      sub_record(association_name, serializer: serializer)
    end

    def belongs_to(association_name, serializer: nil, record_type: nil, polymorphic: false, &block)
      sub_record(association_name, serializer: serializer)
    end

    def sub_record(association_name, serializer: nil, &block)
      if serializer.nil?
        serializer = "#{association_name.to_s.camelize}Serializer".constantize
      end
      sub_records << [association_name, serializer, block]
    end

    def has_many(collection_name, serializer:, record_type: nil, &block)
      collection(collection_name, serializer: serializer, &block)
    end

    def collection(collection_name, serializer:, &block)
      collections << [collection_name, serializer, block]
    end

    # NOOP for fast_jsonapi compatibility
    def set_type(_)
    end

    # NOOP for fast_jsonapi compatibility
    def set_id(_)
    end

    private

    def is_id?(name)
      name == :id || (/.*_id\z/).match?(name.to_s)
    end
  end
end
