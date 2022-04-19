# frozen_string_literal: true

require 'stringio'

module RestClient
  class Request
    # Fake it till you make it...
    FakeNetHTTPResponse = Struct.new(:body, :code, :headers) do
      def to_hash
        headers.each_with_object({}) do |(k, v), h|
          # In Net::HTTP, header values are arrays.
          h[k] = [v]
        end
      end
    end

    # We are overriding this method in order to fix its behavior and make it
    # normalize headers even when they are passed as strings.
    def stringify_headers(headers)
      headers.each_with_object({}) do |(key, value), result|
        key = key.to_s.split(/_/).map(&:capitalize).join('-')
        if key == 'Content-Type'
          result[key] = maybe_convert_extension(value.to_s)
        elsif key == 'Accept'
          # Accept can be composed of several comma-separated values.
          target_values = if value.is_a?(Array)
                            value
                          else
                            value.to_s.split(',')
                          end
          result[key] = target_values.map { |ext| maybe_convert_extension(ext.to_s.strip) }.join(', ')
        else
          result[key] = value.to_s
        end
      end
    end

    alias original_execute execute

    def execute(&block)
      return original_execute(&block) unless RestClient.middleware.any?

      env = to_rack_env
      env.delete_if { |_, v| v.nil? }

      response = RestClient.middleware.build(RestClient.default_app).call(env)
      process_response(env, response, &block)
    end

    private

    def to_rack_env
      rack_env = {
        'REQUEST_METHOD' => @method.to_s.upcase,
        'PATH_INFO' => uri.path || '/',
        'QUERY_STRING' => uri.query || '',
        'SERVER_NAME' => uri.host,
        'SERVER_PORT' => uri.port.to_s,
        'SCRIPT_NAME' => '',
        'rack.input' => payload || StringIO.new.set_encoding('ASCII-8BIT'),
        'rack.errors' => $stderr,
        'rack.version' => ::Rack::VERSION,
        'rack.url_scheme' => uri.scheme
      }

      cl = headers.delete('Content-Length')
      ct = headers.delete('Content-Type')
      rack_env['CONTENT_LENGTH'] = cl if cl && cl.to_i > 0
      rack_env['CONTENT_TYPE'] = ct if ct

      processed_headers.each do |k, v|
        rack_env["HTTP_#{k.tr('-', '_').upcase}"] = v
      end

      rack_env['restclient.request'] = self
      rack_env
    end

    def process_response(env, rack_response, &block)
      status, headers, body = rack_response
      http_res = FakeNetHTTPResponse.new(+'', status.to_i, headers)
      response = if body.respond_to?(:to_path)
                   RawResponse.new(::File.open(body.to_path, 'rb'), http_res, self)
                 else
                   body.each { |part| http_res.body << part.to_s }
                   Response.create(http_res.body, http_res, self)
                 end

      if block
        block.call(response)
      elsif !(200...300).include?(status) && e = env['restclient.error']
        raise e
      else
        response
      end
    ensure
      body.close if body.respond_to?(:close)
    end
  end
end
