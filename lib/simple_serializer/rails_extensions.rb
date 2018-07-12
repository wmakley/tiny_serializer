class SimpleSerializer
  module RailsExtensions
    # Alias of Rails.application.routes.url_helpers
    def url_helpers
      Rails.application.routes.url_helpers
    end

    # Make Rails.logger the default logger.
    def logger
      super || Rails.logger
    end
  end
end
