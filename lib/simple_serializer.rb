require "simple_serializer/version"
require "simple_serializer/dsl"
require "active_support/json"
require "active_support/core_ext/class/attribute"

# Simple ActiveModel::Serializer replacement, with some fast_jsonapi
# compatibility parameters (that do nothing).
#
# One major difference: ID's are serialized as
# strings by default. The reason is that they are just dumb tokens,
# and we don't want to have to worry about them getting messed
# up by becoming doubles when the JSON is parsed.
class SimpleSerializer
  extend DSL

  class_attribute :coerce_ids_to_string, default: false

  attr_accessor :object

  def initialize(object = nil)
    @object = object
  end

  if defined?(Rails)
    require "simple_serializer/rails_extensions"
    include RailsExtensions
  end

  def serializable_hash
    return nil unless @object
    if is_collection?(@object)
      json = []
      return json if @object.empty?
      original_object = @object
      original_object.each do |object|
        @object = object
        json << serialize_object_to_hash
      end
      @object = original_object
      return json
    else
      return serialize_object_to_hash
    end
  end

  alias_method :to_hash, :serializable_hash

  def as_json(options = nil)
    serializable_hash.as_json
  end

  def to_json(options = nil)
    serializable_hash.to_json
  end

  def serialize_object_to_hash
    return nil unless @object
    hash = {}

    self.class.attributes.each do |name, is_id, block|
      if block
        value = instance_exec(@object, &block)
      else
        value = @object.public_send(name)
      end

      if is_id && coerce_ids_to_string?
        hash[name] = serialize_id(value)
      else
        hash[name] = recursively_serialize_object(value)
      end
    end

    self.class.sub_records.each do |name, serializer, block|
      if block
        value = instance_exec(@object, &block)
      else
        value = @object.public_send(name)
      end

      if value
        value = serializer.new(value).serializable_hash
      end
      hash[name] = value
    end

    self.class.collections.each do |collection_name, serializer, block|
      serializer_instance = serializer.new(nil)

      if block
        records = instance_exec(@object, &block)
      else
        records = @object.public_send(collection_name)
      end
      records ||= []

      json = records.map do |record|
        serializer_instance.object = record
        serializer_instance.serializable_hash
      end
      hash[collection_name] = json
    end

    return hash
  end


  class << self
    def serialize(object)
      new(object).serializable_hash
    end

    def serialize_each(collection)
      return new(collection).serializable_hash
    end
  end

  private

  def is_collection?(resource)
    resource.respond_to?(:each) && !resource.respond_to?(:each_pair)
  end

  def serialize_id(id)
    id && id.to_s
  end

  # Only recurses if the object is an Array or Hash
  def recursively_serialize_object(object)
    # return object if object.is_a?(String) # fast out for common case

    # if object.respond_to?(:as_json)
      return object.as_json
    # end

    # TODO: work without ActiveSupport
    # if object.eql?(true) || object.eql?(false) || object.kind_of?(Numeric)
    #   return object
    # end

    # if object.is_a?(Array)
    #   return object.map do |elt|
    #     recursively_serialize_object(elt)
    #   end
    # end

    return object.to_s
  end
end
