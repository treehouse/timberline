require 'forwardable'
require 'json'
require 'logger'
require 'yaml'

require 'redis'
require 'redis-namespace'

require_relative "timberline/version"
require_relative "timberline/config"
require_relative "timberline/queue"
require_relative "timberline/envelope"
require_relative "timberline/queue_manager"

class Timberline
  class << self
    extend Forwardable

    def_delegators :@queue_manager, :error_job, :retry_job, :watch, :push

    attr_reader :config

    def redis=(server)
      initialize_if_necessary
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
      initialize_if_necessary
      if @redis.nil?
        self.redis = Redis.new(@config.redis_config)
      end
      @redis
    end

    def config(&block)
      initialize_if_necessary
      yield @config
    end

    def max_retries
      initialize_if_necessary
      @config.max_retries
    end

    private
    # Don't know if I like doing this, but we want the configuration to be
    # lazy-loaded so as to be sure and give users a chance to set up their
    # configurations.
    def initialize_if_necessary
      @config ||= Config.new
    end
  end

end

Timberline.instance_variable_set("@queue_manager", Timberline::QueueManager.new)
