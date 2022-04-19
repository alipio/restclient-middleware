# frozen_string_literal: true

module RestClient
  module Payload
    class Base
      extend Forwardable

      def_delegators :@stream, :read, :gets, :each
    end
  end
end
