require "simple_serializer/version"
require "simple_serializer/dsl"
require "active_support/json"
require "active_support/core_ext/class/attribute"

# Simple DSL for converting objects to Hashes, which is mostly API-compatible
# with ActiveModel::Serializer. The Hashes can be rendered as JSON by Rails.
#
# I have also added some fast_jsonapi[https://github.com/Netflix/fast_jsonapi]
# API parameters that do nothing, to ease later transition to that library.
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
#     render json: MyObjectSerializer.new(@my_object).serialize
#   end
#
# == RailsExtensions
#
# The RailsExtensions module is automatically prepended when SimpleSerializer
# is used in a Rails app. It defines some small convenience instance methods.
#
class SimpleSerializer
  extend DSL

  if defined?(Rails)
    require "simple_serializer/rails_extensions"
    prepend RailsExtensions
  end

  # Whether to automatically convert "\*_id" properties to String.
  # *default:* _false_
  class_attribute :coerce_ids_to_string, default: false

  # The object to serialize as a Hash
  attr_accessor :object

  # Optional logger object. Defaults to Rails.logger in a Rails app.
  attr_accessor :logger

  # Create a new serializer instance.
  #
  # object::
  #   The object to serialize. Can be a single object or a collection of
  #   objects.
  def initialize(object)
    @object = object
  end

  # Serialize #object as a Hash.
  def serializable_hash(_ = nil)
    return @object unless @object
    return serialize_single_object_to_hash unless collection?

    json = []
    return json if @object.empty?
    original_object = @object
    original_object.each do |object|
      @object = object
      json << serialize_single_object_to_hash
    end
    @object = original_object
    json
  end

  alias to_hash serializable_hash
  alias serialize serializable_hash

  # Serialize #object as a Hash, then call #as_json on the Hash,
  # which will convert keys to Strings.
  #
  # <b>There shouldn't be a need to call this, but we implement it to fully
  # support ActiveSupport's magic JSON protocols.</b>
  def as_json(_ = nil)
    serializable_hash.as_json
  end

  # Serialize #object to a JSON String.
  #
  # Calls #serializable_hash, then call #to_json on the resulting Hash,
  # converting it to a String using the automatic facilities for doing so
  # from ActiveSupport.
  def to_json(_ = nil)
    serializable_hash.to_json
  end

  # Check if #object is a collection.
  def collection?
    @object.respond_to?(:each) && !@object.respond_to?(:each_pair)
  end

  # = Class Methods
  class << self
    # The same as:
    #
    #   SimpleSerializer.new(object).serializable_hash
    def serialize(object)
      new(object).serializable_hash
    end

    alias serialize_each serialize
  end

  private

  # Private serialization implementation for a single object.
  # @object must be set to a single object before calling.
  def serialize_single_object_to_hash
    return @object unless @object

    hash = {}
    serialize_attributes(hash)
    serialize_sub_records(hash)
    serialize_collections(hash)
    hash
  end

  def serialize_attributes(hash)
    self.class.attributes.each do |name, key, is_id, block|
      raw_value = get_attribute(name, block)
      hash[key] = serialize_attribute(raw_value, is_id)
    end
  end

  def get_attribute(name, block)
    if block
      instance_exec(@object, &block)
    else
      @object.public_send(name)
    end
  end

  # Internal algorithm to convert any object to a valid JSON string, scalar,
  # object, array, etc. All objects are passed through this function after they
  # are retrieved from #object. Currently just calls #as_json.
  def serialize_attribute(raw_value, is_id = false)
    if is_id && coerce_ids_to_string?
      serialize_id(raw_value)
    else
      raw_value.as_json
    end
  end

  def serialize_id(id)
    id && id.to_s
  end

  def serialize_sub_records(hash)
    self.class.sub_records.each do |name, key, serializer, block|
      value = get_attribute(name, block)
      value = serializer.new(value).serializable_hash if value
      hash[key] = value
    end
  end

  def serialize_collections(hash)
    self.class.collections.each do |collection_name, key, serializer, block|
      collection = get_collection(collection_name, block)

      serializer_instance = serializer.new(nil)
      json_array = []

      collection.each do |object|
        serializer_instance.object = object
        json_array << serializer_instance.serializable_hash
      end

      hash[key] = json_array
    end
  end

  # Get the collection from #object or block, or [] if nil.
  def get_collection(name, block)
    if block
      instance_exec(@object, &block)
    else
      @object.public_send(name)
    end || []
  end
end
