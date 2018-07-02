# SimpleSerializer

Extremely simple replacement for ActiveModel::Serializers. Not drop-in,
but facilitates getting off of it. It does not infer the serializer
class to use, so you always have to specify and instantiate manually,
and it is always straightforward to do so.

Use only if you have heavily invested in [active_model_serializers](https://github.com/rails-api/active_model_serializers), but have started experiencing the same frustrations I had with it and can't transition to [jsonapi-rb](http://jsonapi-rb.org/) or [fast_jsonapi](https://github.com/Netflix/fast_jsonapi).

![Travis CI Build Status](https://travis-ci.org/wmakley/simple_serializer.svg?branch=master)

**Benefits:**

* Extremely simple and deterministic behavior, no crazy adapter classes and other weirdness.
* Easy to understand; just uses `#as_json` to serialize attributes.
* Simple to use.
* Does not leak memory in development (unlike AMS).
* ~200 lines of code, give or take.

**Downsides:**

* No automatic anything. Must be invoked manually.
* Serializers cannot inherit from each other (yet).
* Just uses `#as_json` to serialize attributes.
* Requires ActiveSupport.
* Performance characteristics unknown.

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

### Usage in Rails:

```ruby
my_object = MyObject.new(1, "Fred", "Flintstone", Date.new(2000, 1, 1))
render json: MyObjectSerializer.new(my_object).serializable_hash
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

The `object` parameter for blocks is optional, as blocks are executed
in the context of the serializer instance. It just makes it easier
to use the [fast_jsonapi](https://github.com/Netflix/fast_jsonapi) gem later if you want.

### Usage with Collections:

Collections are handled automatically:

```ruby
class MyObjectSerializer < SimpleSerializer
  attributes :id, :first_name
end

items = [MyObject.new(1, "Fred"), MyObject.new(2, "Wilma")]
render json: MyObjectSerializer.new(items).serializable_hash
```

Produces:

```json
[ {"id": 1, "name": "Fred"},
  {"id": 2, "name": "Wilma"}
]
```

(Extraneous properties ommitted for clarity).

### Defining Associations and Serializing Sub-Objects

The DSL methods `belongs_to`, `has_one`, and `has_many` are all synonyms for "use this serializer to serialize this property". They are basically syntax sugar for:

```ruby
class MySerializer < SimpleSerializer
  attribute :parent do |object|
    ParentSerializer.new(object.parent).serializable_hash
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
method available for use in custom attribute blocks.


```ruby
class ItemSerializer < SimpleSerializer
  attribute :link do
    url_helpers.item_url(object)
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


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_serializer', git: 'https://github.com/wmakley/simple_serializer.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_serializer

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wmakley/simple_serializer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
