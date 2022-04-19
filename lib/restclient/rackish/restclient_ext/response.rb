# frozen_string_literal: true

module RestClient
  class Response
    def rack_body
      [body]
    end
  end
end
