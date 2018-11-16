# frozen_string_literal: true

class TinySerializer
  # Small convenience improvements to TinySerializer
  # that are automatically included as serializer instance methods
  # when used in a Rails app.
  module RailsExtensions
    # Alias of +Rails.application.routes.url_helpers+.
    def url_helpers
      Rails.application.routes.url_helpers
    end

    # Return +Rails.logger+ if TinySerializer#logger is not set.
    def logger
      super || Rails.logger
    end
  end
end
