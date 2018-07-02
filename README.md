# SimpleSerializer

Extremely simple replacement for ActiveModel::Serializers. Not drop-in,
but facilitates getting off of it. It does not infer the serializer
class to use, so you always have to specify and instantiate manually,
and it is always straightforward to do so.

![Travis CI Build Status](https://travis-ci.org/wmakley/simple_serializer.svg?branch=master)

**Benefits:**

* Extremely simple and deterministic behavior, no crazy adapter classes and other weirdness.
* Easy to understand.
* Simple to use.
* Does not leak memory in development (unlike AMS).

**Downsides:**

* No automatic anything. Must be invoked manually.
* Serializers cannot inherit from each other (yet).
* Just uses `#as_json` to serialize objects, nothing fancy or intelligent.

## Usage

**Serializer definition:**

```ruby
MyObject = Struct.new(:id, :first_name, :last_name, :date)

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

**Usage in Rails:**

```ruby
my_object = MyObject.new(1, "Fred", "Flintstone", Date.new(2000, 1, 1))
render json: MyObjectSerializer.new(my_object).serializable_hash
```

The `object` parameter for blocks is optional, as blocks are executed
in the context of the serializer instance. it just makes it easier
to use the *fast_jsonapi* gem later if you want.

### Associations

The DSL methods `belongs_to` and `has_one` are both synonyms for "use this serializer to serialize this property". They are just syntax sugar for:

```ruby
class MySerializer < SimpleSerializer
  attribute :parent do
    ParentSerializer.new(object.parent).serializable_hash
  end
end
```

`has_many` works the same way, but for collections.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_serializer'
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
