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
      @redis = server
    end

    def redis
      if @redis.nil?
        r = Redis.new(Config.redis_config)
        @redis = Redis::Namespace.new(Config.namespace, :redis => r)
      else
        @redis
      end
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
