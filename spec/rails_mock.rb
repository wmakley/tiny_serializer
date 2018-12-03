# frozen_string_literal: true

# Mock Rails module. Avoid loading all of Rails just to test
# that RailsExtensions#url_helpers passes the correct arguments.
module Rails
  def self.application
    Application
  end

  module Application
    def self.routes
      Routes
    end

    module Routes
      def self.url_helpers
        UrlHelpers
      end

      module UrlHelpers
        def self.object_url(object, options = {})
          "/api/objects/#{object.id}"
        end
      end
    end
  end
end

puts "MOCK RAILS LOADED"