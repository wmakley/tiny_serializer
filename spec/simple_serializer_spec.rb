require "spec_helper"
require "date"

RSpec.describe SimpleSerializer do
  # Build a new SimpleSerializer subclass. string and/or block will be evaluated
  # in class context.
  def serializer(string = nil, &block)
    klass = Class.new(SimpleSerializer)
    klass.class_eval(string) if string
    klass.class_eval(&block) if block_given?
    klass
  end

  TestStruct = Struct.new(:id, :name, :date, :boolean, :sub_object, :collection_items)

  def sub_object
    nil
  end

  let(:object) do
    TestStruct.new(1, "test", Date.new(2000, 1, 1), true, sub_object, [])
  end

  class SubObjectSerializer < SimpleSerializer
    attributes :id, :name
  end

  context "when @object is a collection" do
    it "serializes each item in the collection" do
      collection = [TestStruct.new(1, "test1"), TestStruct.new(2, "test2")]
      expect(SubObjectSerializer.new(collection).serializable_hash).to eq(
        [{ id: 1, name: "test1" }, { id: 2, name: "test2"}]
      )
    end
  end


  describe "#serializable_hash" do
    subject(:hash) do
      serializer.new(object).serializable_hash
    end

    it "builds a hash" do
      expect(subject).to be_a(Hash)
    end

    context "when coerce_ids_to_string is true" do
      Klass = Struct.new(:id, :parent_id)

      def serializer
        super do
          self.coerce_ids_to_string = true
          attributes :id, :parent_id
        end
      end

      it "converts ids to string" do
        object = Klass.new(1, 2)
        expect(serializer.new(object).serializable_hash).to eq({ id: "1", parent_id: "2" })
      end
    end

    context "when an attribute is defined without a block" do
      def serializer
        super do
          attribute :id
        end
      end

      it "builds a hash by copying the named property from @object" do
        expect(subject[:id]).to eq(1)
      end
    end

    context "when an attribute is defined with a block that takes no arguments" do
      def serializer
        super do
          attribute :id do
            object.name
          end
        end
      end
      it "evaluates the block in the context of the serializer instance" do
        hash = serializer.new(object).serializable_hash
        expect(hash).to eq({ id: "test" })
      end
    end

    context "when an attribute is defined with a block that takes one argument" do
      def serializer
        super do
          attribute :id do |object|
            object.date
          end
        end
      end
      it "passes @object as the block argument" do
        hash = serializer.new(object).serializable_hash
        expect(hash).to eq({ id: "2000-01-01" })
      end
    end

    context "when multiple attributes are defined" do
      def serializer
        super do
          attributes :id, :name, :date, :boolean
        end
      end

      it "builds a hash by copying all the named properties from @object" do
        expect(subject).to eq({
          id: 1,
          name: "test",
          date: "2000-01-01",
          boolean: true
        })
      end
    end

    context "when belongs_to relationship is defined" do
      def object_serializer
        serializer do
          attribute :id
          belongs_to :sub_object, serializer: SubObjectSerializer
        end
      end

      let(:sub_object) { TestStruct.new(2, "Sub-Object", Date.parse("2000-01-01"), true) }
      let(:object) { TestStruct.new(1, "test", Date.parse("2000-01-01"), true, sub_object) }

      subject do
        object_serializer.new(object).serializable_hash
      end

      it "serializes the sub_object recursively" do
        expect(subject).to eq(
          id: 1,
          sub_object: {
            id: 2,
            name: "Sub-Object"
          }
        )
      end
    end

    context "when belongs_to relationship is defined without a serializer" do
      def object_serializer
        serializer do
          belongs_to :sub_object
        end
      end

      def sub_object
        TestStruct.new("2", "Sub-Object")
      end

      subject do
        object_serializer.new(object).serializable_hash
      end

      it "guesses the serializer class from the name" do
        expect(subject).to eq(
          sub_object: {
            id: "2",
            name: "Sub-Object"
          }
        )
      end
    end

    context "when a collection relationship is defined" do
      class CollectionSerializer < SimpleSerializer
        attributes :id, :name
      end

      def object_serializer
        serializer do
          has_many :collection_items, serializer: CollectionSerializer
        end
      end

      let :object do
        elt1 = TestStruct.new(2, "ELT 1")
        elt2 = TestStruct.new(3, "ELT 2")
        TestStruct.new(1, "test", Date.new(2000, 1, 1), true, nil, [elt1, elt2])
      end

      subject do
        object_serializer.new(object).serializable_hash
      end

      it "uses the designizated serializer to serialize each object in the collection as an Array" do
        expect(subject).to eq(
          collection_items: [
            { id: 2, name: "ELT 1" },
            { id: 3, name: "ELT 2" }
          ]
        )
      end

      it "treats a nil collection as an empty Array" do
        klass = serializer do
          has_many :items, serializer: CollectionSerializer do
            nil
          end
        end

        expect(klass.new(object).serializable_hash).to eq(
          items: []
        )
      end
    end

    context "when an attribute returns an Array" do
      it "serializes the Array as an Array" do
        object = TestStruct.new([1, 2, 3])
        klass = serializer do
          attribute :id
        end
        expect(klass.new(object).serializable_hash).to eq(id: [1, 2, 3])
      end
    end
  end

  # TODO: move this into its own file?
  describe "DSL" do
    describe "#collection" do
      context "when serializer is nil" do
        class CollectionItemSerializer < SimpleSerializer
          attributes :id, :boolean
        end
        it "infers the serializer class from the collection name" do
          subject = serializer do
            collection :collection_items
          end
          expect(subject.send(:collections)[0][2]).to eq(CollectionItemSerializer)
        end
      end
    end

    describe "#attributes" do
      it "is inheritable by subclasses" do
        s1 = serializer do
          attribute :id
        end

        s2 = Class.new(s1)
        expect(s2.attribute_names).to eq([:id])
      end

      it "is extendable by subclasses" do
        s1 = serializer do
          attribute :id
        end

        s2 = Class.new(s1)
        s2.class_eval do
          attribute :name
        end

        expect(s1.attribute_names).to eq([:id])
        expect(s2.attribute_names).to eq([:id, :name])
      end
    end

    describe "#sub_records" do
      it "is inheritable by subclasses" do
        s1 = serializer do
          sub_record :sub_object, serializer: SubObjectSerializer
        end

        s2 = Class.new(s1)
        expect(s2.sub_record_names).to eq([:sub_object])
      end

      it "is extendable by subclasses" do
        s1 = serializer do
          sub_record :sub_object, serializer: SubObjectSerializer
        end

        s2 = Class.new(s1)
        s2.class_eval do
          sub_record :sub_object_2, serializer: SubObjectSerializer
        end

        expect(s1.sub_record_names).to eq([:sub_object])
        expect(s2.sub_record_names).to eq([:sub_object, :sub_object_2])
      end
    end

    describe "#collections" do
      it "is inheritable by subclasses" do
        s1 = serializer do
          collection :items, serializer: SubObjectSerializer
        end

        s2 = Class.new(s1)
        expect(s2.collection_names).to eq([:items])
      end

      it "is extendable by subclasses" do
        s1 = serializer do
          collection :items, serializer: SubObjectSerializer
        end

        s2 = Class.new(s1)
        s2.class_eval do
          collection :items_2, serializer: SubObjectSerializer
        end

        expect(s1.collection_names).to eq([:items])
        expect(s2.collection_names).to eq([:items, :items_2])
      end
    end
  end

  describe ".serialize_each" do
    def serializer
      super do
        attribute :id
      end
    end
    it "works" do
      collection = [TestStruct.new(1), TestStruct.new(2)]
      expect(serializer.serialize_each(collection)).to eq(
        [
          { id: 1 },
          { id: 2 }
        ]
      )
    end
  end
end
