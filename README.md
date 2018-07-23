# SimpleSerializer

Simple DSL for converting objects to Hashes, which is mostly API-compatible with
[ActiveModel::Serializers](https://github.com/rails-api/active_model_serializers).
Not quite a drop-in replacement, but facilitates migrating away from it.
The resulting Hashes can be rendered as JSON by Rails using the ActiveSupport::JSON
module.

Unlike AMS, it does **not** integrate with Rails for automatic usage with the `render` function,
which has proven to be one of the biggest sources of confusion and complexity for me.
`render json: @object` will continue to work exactly as it does in a base Rails setup.

Use if you have heavily invested in [active_model_serializers](https://github.com/rails-api/active_model_serializers), but have started experiencing the same frustrations I had with it and can't transition to [jsonapi-rb](http://jsonapi-rb.org/) or [fast_jsonapi](https://github.com/Netflix/fast_jsonapi).

![Travis CI Build Status](https://travis-ci.org/wmakley/simple_serializer.svg?branch=master)

**Benefits:**

* Extremely simple and deterministic behavior; no adapter classes and other complications. Just turns Objects into Hashes.
* Easy to understand; uses `#as_json` to serialize attributes.
* Simple and explicit invocation.
* Does not leak memory in development.
* ~200 lines of code, give or take.
* Seems pretty darn fast, at least as fast as `public_send`, `Hash#[]=`, and `Hash#to_json` can be.

**Downsides:**

* Uses `#as_json` to serialize attributes (maybe unintended consequences, especially with complex objects).
* Requires ActiveSupport.

## Usage

### Serializer definition:

```ruby
MyObject = Struct.new(:id, :first_name, :last_name, :date) do
  def parent; nil; end
  def sub_record; nil; end
  def related_items; []; end
end

class MyObjectSerializer < SimpleSerializer
  attributes :id,
             :first_name,
             :last_name,
             :date

  belongs_to :parent, serializer: ParentSerializer
  has_one :sub_record # serializer will be inferred to be SubRecordSerializer
  has_many :related_items, serializer: RelatedItemSerializer

  attribute :full_name do |object|
    "#{object.first_name} #{object.last_name}"
  end
end
```

**Notes on blocks:**

The `object` parameter for blocks is optional, as blocks are executed
in the context of the serializer instance. It just makes it easier
to use the [fast_jsonapi](https://github.com/Netflix/fast_jsonapi) gem later if you want.

### Usage:

```ruby
object = MyObject.new(...)
# Several ways to invoke the serializer are available:
MyObjectSerializer.new(object).serialize
MyObjectSerializer.serialize(object)
```

Produces:

```json
{
  "id": 1,
  "first_name": "Fred",
  "last_name": "Flintstone",
  "date": "2000-01-01",
  "full_name": "Fred Flintstone",
  "parent": null,
  "sub_record": null,
  "related_items": []
}
```

With collections:

```ruby
class IdOnlySerializer < SimpleSerializer
  attribute :id
end

objects = [MyObject.new(1), MyObject.new(2)]
IdOnlySerializer.new(objects).serialize # this still works
IdOnlySerializer.serialize_each(objects) # this works too
IdOnlySerializer.serialize(objects) # this still works
```

Produces:

```json
[
  { "id": 1 },
  { "id": 2 }
]
```

### Usage in Rails:

In Rails, calling `.serialize` is optional because **SimpleSerializer** implements all the 'magic' methods (`as_json`, `to_json`, and `serializable_hash`), although I'm not the biggest fan (it loses some explicitness):

```ruby
my_object = MyObject.new(1, "Fred", "Flintstone", Date.new(2000, 1, 1))
render json: MyObjectSerializer.new(my_object)
```

### Under the Hood

Takes every attribute you define, and uses it to call `#public_send` on the object to serialize,
then uses `#as_json` to serialize the resulting value. If you define the attribute with a block, it will call the block to get the value instead.

### Usage with Collections:

Collections are handled automatically:

```ruby
class MyObjectSerializer < SimpleSerializer
  attributes :id, :first_name
end

items = [
  MyObject.new(1, "Fred"),
  MyObject.new(2, "Wilma")
]
render json: MyObjectSerializer.new(items).serialize
```

Produces:

```json
[
  {"id": 1, "name": "Fred"},
  {"id": 2, "name": "Wilma"}
]
```

### Defining Associations and Serializing Sub-Objects

The DSL methods `belongs_to`, `has_one`, and `has_many` are all synonyms for "use this serializer to serialize this property". They are basically syntax sugar for:

```ruby
class MySerializer < SimpleSerializer
  attribute :parent do |object|
    ParentSerializer.new(object.parent).serialize
  end
end
```

These methods all optionally take a block, which you can use to customize the
object or collection. For example, to avoid loading every single item in a
has_many relation:

```ruby
class MySerializer < SimpleSerializer
  has_many :items, serializer: ItemSerializer do |object|
    object.items.limit(100)
  end
end
```

### Links and URL's

When used with Rails, serializer instances have the `#url_helpers`
method available.


```ruby
class ItemSerializer < SimpleSerializer
  attribute :link do
    url_helpers.item_path(object)
  end
end
```

### Notes on ID's.

If you use UUID's or don't want ID's to be serialized as numeric types,
you can have them automatically detected and coerced to Strings.

```ruby
class MyObjectSerializer < SimpleSerializer
  self.coerce_ids_to_string = true
end
```

To enable globally, but opt out for a specific attribute:

```ruby
class MyObjectSerializer < SimpleSerializer
  self.coerce_ids_to_string = true

  attribute :id, is_id: false
end
```

### Attribute Inheritance

Attributes are inherited from parent classes, but can be extended.
This example works as you would expect from [active_model_serializers](https://github.com/rails-api/active_model_serializers)
(the `name` attribute will only appear if you use `MyObjectSerializer::WithName.serialize(my_object)`):

```ruby
class MyObjectSerializer < SimpleSerializer
  attribute :id

  class WithName < MyObjectSerializer
    attribute :name
  end
end
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_serializer', git: 'https://github.com/wmakley/simple_serializer.git'
```

And then execute:

    $ bundle

I will push it to rubygems.org once I pick a new name!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wmakley/simple_serializer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
