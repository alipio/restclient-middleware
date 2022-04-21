# frozen_string_literal: true

require 'rack'
require 'restclient'

require_relative 'rackish/middleware_chain'
require_relative 'rackish/restclient_ext'
require_relative 'rackish/logging/middleware'

module RestClient
  class << self
    extend Forwardable

    def_delegators :middleware, :unshift, :insert_before, :insert_after, :delete!, :use

    def middleware
      @middleware ||= Rackish::MiddlewareChain.new
      yield @middleware if block_given?
      @middleware
    end

    def default_app
      @default_app ||= RestClient::Rackish.new
    end
  end

  class Rackish
    NON_PREFIXED_HEADERS = %w[CONTENT_LENGTH CONTENT_TYPE].freeze

    def initialize(_app = nil)
      @app = ->(env) { env.delete('restclient.response').to_rack_response }
    end

    def call(env)
      request = restore_request(env)

      begin
        env['restclient.response'] = request.execute_without_chain
      rescue ExceptionWithResponse => e
        raise e if e.response.nil?

        env['restclient.error']     = e
        env['restclient.response']  = e.response
      end

      @app.call(env)
    end

    private

    def restore_request(env)
      request = env['restclient.request']
      # Rack already provides a convenient helper that can be used to rebuild the
      # url, so let's use it.
      uri = URI.parse(Rack::Request.new(env).url)
      request.instance_variable_set('@uri', uri)

      headers = request.processed_headers
      headers.clear

      env.each do |name, value|
        next unless name.is_a?(String) && value.is_a?(String)

        if NON_PREFIXED_HEADERS.include?(name) || name.start_with?('HTTP_')
          name = name.sub(/^HTTP_/, '').downcase.tr('_', '-')
          headers[name] = value
        end
      end

      payload = env['rack.input'].read
      payload = payload.empty? ? nil : Payload.generate(payload)
      request.instance_variable_set('@payload', payload)

      request
    end
  end
end
