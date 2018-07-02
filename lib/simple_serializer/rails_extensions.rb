class SimpleSerializer
  module RailsExtensions
    def url_helpers
      Rails.application.routes.url_helpers
    end
  end
end
