require 'json'
require 'logger'

require 'redis'
require 'redis-namespace'

require_relative "treeline/version"
require_relative "treeline/queue"
require_relative "treeline/envelope"

class Treeline
  class << self
    def redis=(server)
      if server.is_a? Redis
        @redis = Redis::Namespace.new(Config.namespace, :redis => server)
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
        r = Redis.new(Config.redis_config)
        @redis = Redis::Namespace.new(Config.namespace, :redis => r)
      end

      @redis
    end

    def config(&block)
      yield Config
    end
  end

  class Config
    class << self
      attr_accessor :database, :host, :port, :timeout, :password, :logger, :namespace

      def namespace
        @namespace ||= 'treeline'
      end

      def redis_config
        config = {}

        { :db => database, :host => host, :port => port, :timeout => timeout, :password => password, :logger => logger }.each do |name, value|
          config[name] = value unless value.nil?
        end

        config
      end
    end
  end
  
end
