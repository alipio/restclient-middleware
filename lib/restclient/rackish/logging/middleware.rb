# frozen_string_literal: true

require 'logger'
require 'json'

module RestClient
  module Logging
    class Middleware
      DEFAULT_OPTIONS = { headers: true, bodies: false,
                          log_level: :info }.freeze

      def initialize(app, logger = nil, opts = {})
        @app = app
        @logger = logger || ::Logger.new($stdout)
        @id = SecureRandom.hex(4)
        @opts = DEFAULT_OPTIONS.merge(opts)
      end

      def call(env)
        response = @app.call(env)

        log_request(env)
        log_response(env, response)

        response
      end

      private

      BASIC_HEADERS = %w[
        REQUEST_METHOD
        SERVER_NAME
        SERVER_PORT
        PATH_INFO
        QUERY_STRING
      ].freeze

      def log_request(env)
        log('request') do |hash|
          if @opts[:headers]
            hash.merge!(env.select { |_, v| v.is_a?(String) })
          else
            hash.merge!(env.select { |k, _| BASIC_HEADERS.include?(k) })
          end

          body = env['rack.input'].read
          hash['body'] = body if !body.empty? && @opts[:bodies]
        end
      end

      def log_response(_env, response)
        code, headers, body = response

        log('response') do |hash|
          hash['status_code'] = code.to_i
          hash['headers'] = headers if @opts[:headers]

          body = get_real_body(body) || ''
          hash['body'] = body if !body.empty? && @opts[:bodies]
        end
      end

      def get_real_body(body)
        unless body.respond_to?(:to_ary)
          @logger.warn('Body is a kind of streaming or file-like body and it must only be called once, skipping.')
          return nil
        end

        body.to_ary.join
      end

      def log(event)
        hash = {
          'timestamp' => Time.now.strftime('%FT%T.%3N%:z'),
          'request_log_id' => @id,
          'event' => event
        }
        yield(hash) if block_given?
        @logger.info(event) { JSON.generate(hash) }
      end
    end
  end
end
