class SimpleSerializer
  module RailsExtensions
    def url_helpers
      Rails.application.routes.url_helpers
    end

    def logger
      super || Rails.logger
    end
  end
end
