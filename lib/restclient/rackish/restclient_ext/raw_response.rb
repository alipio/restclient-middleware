# frozen_string_literal: true

module RestClient
  class RawResponse
    def rack_body
      file
    end
  end
end
