# frozen_string_literal: true

module RestClient
  module AbstractResponse
    def rack_body
      raise NotImplementedError, "You must implement #{self.class}##{__method__}"
    end

    def to_rack_response
      headers = {}
      raw_headers.each do |key, value|
        headers[key.downcase] = value.join(', ')
      end
      headers.delete('status')

      [code, headers, rack_body]
    end
  end
end
