# frozen_string_literal: true

class SimpleSerializer
  # Small convenience improvements to SimpleSerializer
  # that are automatically included as serializer instance methods
  # when used in a Rails app.
  module RailsExtensions
    # Shortcut to +Rails.application.routes.url_helpers+.
    def url_helpers
      Rails.application.routes.url_helpers
    end

    # Return +Rails.logger+ if SimpleSerializer#logger is not set.
    def logger
      super || Rails.logger
    end
  end
end
