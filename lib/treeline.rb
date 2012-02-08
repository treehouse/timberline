require 'json'
require 'logger'
require 'yaml'

require 'redis'
require 'redis-namespace'

require_relative "treeline/version"
require_relative "treeline/config"
require_relative "treeline/queue"
require_relative "treeline/envelope"

class Treeline
  class << self
    def redis=(server)
      # Make sure the configuration is initialized if it isn't already
      @config ||= Config.new
      if server.is_a? Redis
        @redis = Redis::Namespace.new(@config.namespace, :redis => server)
      elsif server.is_a? Redis::Namespace
        @redis = server
      elsif server.nil?
        @redis = nil
      else
        raise "Not a valid Redis connection."
      end
    end

    def redis
      if @redis.nil?
        self.redis = Redis.new(@config.redis_config)
      end

      @redis
    end

    def config(&block)
      @config ||= Config.new
      yield @config
    end
  end

end
