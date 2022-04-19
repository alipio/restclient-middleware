# frozen_string_literal: true

module RestClient
  class Rackish
    class MiddlewareStack
      class Middleware
        attr_reader :args, :klass

        def initialize(klass, args)
          @klass = klass
          @args  = args
        end

        def name
          klass.name
        end

        def ==(other)
          case other
          when Middleware
            klass == other.klass
          when Class
            klass == other
          end
        end

        def build(app)
          klass.new(app, *args)
        end
      end

      attr_accessor :middlewares

      def initialize(*_args)
        @middlewares = []
        yield self if block_given?
      end

      def any?
        middlewares.any?
      end

      def unshift(klass, *args)
        middlewares.unshift(build_middleware(klass, args))
      end

      def insert_before(index, klass, *args)
        index = assert_index(index, :before)
        middlewares.insert(index, build_middleware(klass, args))
      end

      def insert_after(index, klass, *args)
        index = assert_index(index, :after)
        middlewares.insert(index + 1, build_middleware(klass, args))
      end

      def delete(target)
        middlewares.reject! { |m| m.name == target.name }
      end

      def delete!(target)
        delete(target) || (raise "No such middleware to remove: #{target.inspect}")
      end

      def use(klass, *args)
        middlewares.push(build_middleware(klass, args))
      end

      def build(app = nil, &block)
        middlewares.freeze.reverse.inject(app || block) do |a, e|
          e.build(a)
        end
      end

      private

      def assert_index(index, where)
        i = index.is_a?(Integer) ? index : index_of(index)
        raise "No such middleware to insert #{where}: #{index.inspect}" unless i

        i
      end

      def build_middleware(klass, args)
        Middleware.new(klass, args)
      end

      def index_of(klass)
        middlewares.index do |m|
          m.name == klass.name
        end
      end
    end
  end
end
