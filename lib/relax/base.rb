module Relax
  class Base
    def self.redis
      if uri = ENV['REDISCLOUD_URL']
        redis_uri = URI.parse(uri)
      elsif uri = ENV['REDISTOGO_URL']
        redis_uri = URI.parse(uri)
      elsif uri = ENV['REDIS_URL']
        redis_uri = URI.parse(uri)
      else
        redis_uri = URI.parse("redis://localhost:6379")
      end

      if !defined?(@@conn)
        timeout = ENV.fetch('RELAX_REDIS_CONN_POOL_TIMEOUT') { 1 }
        size = ENV.fetch('RELAX_REDIS_CONN_POOL_SIZE') { 2 }

        @@conn = ConnectionPool.new(timeout: timeout.to_i, size: size.to_i) do
          Redis.new(url: redis_uri, db: 0)
        end
      end

      @@conn
    end
  end
end
