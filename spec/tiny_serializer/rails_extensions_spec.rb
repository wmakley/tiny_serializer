# frozen_string_literal: true
require 'rails_mock'
require 'spec_helper'

RSpec.describe "TinySerializer::RailsExtensions" do
  MyObject = Struct.new(:id)

  class MyObjectSerializer < TinySerializer
    attribute :id
    attribute :url do |object|
      url_helpers.object_url(object)
    end
  end

  it "is prepended to TinySerializer when Rails is defined" do
    expect(MyObjectSerializer.included_modules).to include(TinySerializer::RailsExtensions)
  end

  describe "#url_helpers" do
    it "calls Rails.application.routes.url_helpers" do
      obj = MyObject.new(1)
      expect(Rails.application.routes.url_helpers).to receive(:object_url).with(obj)
      MyObjectSerializer.serialize(obj)
    end
  end
end
