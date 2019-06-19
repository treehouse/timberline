require 'json'
require 'logger'
require 'yaml'

require 'redis'
require 'redis-namespace'
require 'redis-expiring-set/monkeypatch'

require_relative "timberline/version"
require_relative "timberline/exceptions"
require_relative "timberline/config"
require_relative "timberline/queue"
require_relative "timberline/envelope"

require_relative "timberline/worker"
require_relative "timberline/anonymous_worker"

# The Timberline class serves as a base namespace for Timberline libraries, but
# also provides some convenience methods for accessing queues and quickly and
# easily processing items.
#
class Timberline
  class << self
    attr_reader :config
    attr_accessor :watch_proc
  end

  # Update the redis server that Timberline uses for its connections.
  #
  # If Timberline has not already been configured, this method will initialize
  # a new Timberline::Config first.
  #
  # @param [Redis, Redis::Namespace, nil] server if Redis, wraps it in a namespace.
  #   if Redis::Namespace, uses that namespace directly. If nil, clears out any reference
  #   to the existing redis server.
  #
  # @raise [StandardError] if server is not an instance of Redis, Redis::Namespace, or nil.
  #
  def self.redis=(server)
    initialize_if_necessary
    if server.is_a? Redis
      @redis = Redis::Namespace.new(@config.namespace, redis: server)
    elsif server.is_a? Redis::Namespace
      @redis = server
    elsif server.nil?
      @redis = nil
    else
      raise "Not a valid Redis connection."
    end
  end

  # Obtain a reference to the redis connection that Timberline is using.
  #
  # If Timberline has not already been configured, this method will initialize
  # a new Timberline::Config first.
  #
  # If a Redis connection has not yet been established, this method will establish one.
  #
  # @return [Redis::Namespace]
  #
  def self.redis
    initialize_if_necessary
    if @redis.nil?
      self.redis = Redis.new(@config.redis_config)
    end

    @redis
  end

  # @return [Array<Timberline::Queue>] a list of all non-hidden queues for this
  #   instance of Timberline
  def self.all_queues
    Timberline.redis.smembers("timberline_queue_names").map { |name| queue(name) }
  end

  # Convenience method to create a new Queue object
  # @see Timberline::Queue#initialize
  def self.queue(queue_name, opts = {})
    Queue.new(queue_name, opts)
  end

  # Convenience method to push an item onto a queue
  # @see Timberline::Queue#push
  def self.push(queue_name, data, metadata={})
    queue(queue_name).push(data, metadata)
  end

  # Convenience method to retry a queue item
  # @see Timberline::Queue#retry_item
  def self.retry_item(item)
    origin_queue = queue(item.origin_queue)
    origin_queue.retry_item(item)
  end

  # Convenience method to error out a queue item
  # @see Timberline::Queue#error_item
  def self.error_item(item)
    origin_queue = queue(item.origin_queue)
    origin_queue.error_item(item)
  end

  # Convenience method to pause a Queue by name.
  # @see Timberline::Queue#pause
  def self.pause(queue_name)
    queue(queue_name).pause
  end

  # Convenience method to unpause a Queue by name.
  # @see Timberline::Queue#unpause
  def self.unpause(queue_name)
    queue(queue_name).unpause
  end

  # Method for providing custom configuration by yielding the config object.
  # Lazy-loads the Timberline configuration.
  # @param [Block] block a block that accepts and manipulates a Timberline::Config
  #
  def self.configure(&block)
    initialize_if_necessary
    yield @config
  end

  # Lazy-loads the Timberline configuration.
  # @return [Integer] the maximum number of retries
  def self.max_retries
    initialize_if_necessary
    @config.max_retries
  end

  # Lazy-loads the Timberline configuration.
  # @return [Integer] the stat_timeout expressed in minutes
  def self.stat_timeout
    initialize_if_necessary
    @config.stat_timeout
  end

  # Lazy-loads the Timberline configuration.
  # @return [Integer] the stat_timeout expressed in seconds
  def self.stat_timeout_seconds
    initialize_if_necessary
    @config.stat_timeout * 60
  end

  # Lazy-loads the Timberline configuration.
  # @return [Boolean] whether we want to record result stats for each job in a redis queue
  def self.log_job_results?
    initialize_if_necessary
    @config.log_job_result_stats
  end

  # Create and start a new AnonymousWorker with the given
  # queue_name and block. Convenience method.
  #
  # @param [String] queue_name the name of the queue to watch.
  # @param [Block] block the block to execute for each queue item
  # @see Timberline::AnonymousWorker#watch
  #
  def self.watch(queue_name, &block)
    Timberline::AnonymousWorker.new(&block).watch(queue_name)
  end

  # Update the logger used by Timberline
  #
  # @param [Logger]
  #
  def self.logger=(logger)
    @@logger = logger
  end

  # Get the logger used by Timberline. If no logger is already
  # used, it creates a stdout logger.
  #
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

private
  def self.initialize_if_necessary
    @config ||= Config.new
  end
end
