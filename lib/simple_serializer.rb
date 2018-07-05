require "simple_serializer/version"
require "simple_serializer/dsl"
require "active_support/json"
require "active_support/core_ext/class/attribute"

# Simple ActiveModel::Serializer replacement, with some fast_jsonapi[https://github.com/Netflix/fast_jsonapi]
# compatibility parameters (that do nothing).
#
# == Usage
#
#   # my_object.rb
#   MyObject = Struct.new(:id, :first_name, :last_name, :date) do
#     def parent; nil; end
#     def sub_record; nil; end
#     def related_items; []; end
#   end
#
#   # my_object_serializer.rb
#   class MyObjectSerializer < SimpleSerializer
#     attributes :id,
#                :first_name,
#                :last_name,
#                :date
#
#     belongs_to :parent, serializer: ParentSerializer
#     has_one :sub_record # serializer will be inferred to be SubRecordSerializer
#     has_many :related_items, serializer: RelatedItemSerializer
#
#     attribute :full_name do
#       "#{object.first_name} #{object.last_name}"
#     end
#   end
#
#   # my_objects_controller.rb
#   def show
#     @my_object = MyObject.new(1, "Fred", "Flintstone", Date.new(2000, 1, 1))
#     render json: MyObjectSerializer.new(@my_object).serializable_hash
#   end
#
class SimpleSerializer
  extend DSL

  if defined?(Rails)
    require "simple_serializer/rails_extensions"
    include RailsExtensions
  end


  # Whether to automatically convert "\*_id" properties to String. *default:* _false_
  class_attribute :coerce_ids_to_string, default: false

  # The object to serialize as a Hash
  attr_accessor :object


  # Create a new serializer instance.
  #
  # object::
  #   The object to serialize. Can be a single object or a collection of objects.
  def initialize(object)
    @object = object
  end

  # Serialize #object as a Hash.
  def serializable_hash
    return nil unless @object
    if is_collection?
      json = []
      return json if @object.empty?
      original_object = @object
      original_object.each do |object|
        @object = object
        json << serialize_single_object_to_hash
      end
      @object = original_object
      return json
    else
      return serialize_single_object_to_hash
    end
  end

  alias_method :to_hash, :serializable_hash
  alias_method :serialize, :serializable_hash

  # Serialize #object as a Hash, then call #as_json on the Hash,
  # which will convert keys to Strings (as they are in JSON objects).
  #
  # <b>There shouldn't be a need to call this, but we implement it to fully support
  # ActiveSupport's magic JSON protocols.</b>
  def as_json(options = nil)
    serializable_hash.as_json
  end

  # Serialize #object to a JSON String.
  #
  # Calls #serializable_hash, then call #to_json on the resulting Hash, converting it
  # to a String using the automatic facilities for doing so from ActiveSupport.
  def to_json(options = nil)
    serializable_hash.to_json
  end

  # Check if #object is a collection.
  def is_collection?
    @object.respond_to?(:each) && !@object.respond_to?(:each_pair)
  end

  # = Class Methods
  class << self
    # Serialize a single object as a Hash
    #
    # object::
    #   Can be a single object or a collection of objects
    #
    # Exactly the same as:
    #
    #   new(object).serializable_hash
    #
    def serialize(object)
      new(object).serializable_hash
    end

    alias_method :serialize_each, :serialize
  end

  private

  # Private serialization implementation for a single object.
  # @object must be set to a single object before calling.
  def serialize_single_object_to_hash
    return nil unless @object
    hash = {}

    self.class.attributes.each do |name, key, is_id, block|
      if block
        value = instance_exec(@object, &block)
      else
        value = @object.public_send(name)
      end

      if is_id && coerce_ids_to_string?
        hash[key] = serialize_id(value)
      else
        hash[key] = convert_object_to_json(value)
      end
    end

    self.class.sub_records.each do |name, key, serializer, block|
      if block
        value = instance_exec(@object, &block)
      else
        value = @object.public_send(name)
      end

      if value
        value = serializer.new(value).serializable_hash
      end
      hash[key] = value
    end

    self.class.collections.each do |collection_name, key, serializer, block|
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
      hash[key] = json
    end

    return hash
  end

  # Internal algorithm to convert any object to a valid JSON string, scalar, object, array, etc.
  # All objects are passed through this function after they are retrieved from #object.
  # Currently just calls #as_json.
  def convert_object_to_json(object)
    return object.as_json
  end

  def serialize_id(id)
    id && id.to_s
  end
end
