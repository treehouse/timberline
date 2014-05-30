require 'json'
require 'logger'
require 'yaml'

require 'redis'
require 'redis-namespace'
require 'redis-expiring-set/monkeypatch'

require_relative "timberline/version"
require_relative "timberline/config"
require_relative "timberline/queue"
require_relative "timberline/envelope"

class Timberline
  class << self
    attr_reader :config
  end

  def self.redis=(server)
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

  def self.redis
    initialize_if_necessary
    if @redis.nil?
      self.redis = Redis.new(@config.redis_config)
    end

    @redis
  end

  def self.all_queues
    Timberline.redis.smembers("timberline_queue_names").map { |name| queue(name) }
  end

  def self.error_queue
    @error_queue ||= Queue.new("timberline_errors")
  end

  def self.queue(queue_name)
    if @queue_list[queue_name].nil?
      @queue_list[queue_name] = Queue.new(queue_name)
    end
    @queue_list[queue_name]
  end

  def self.push(queue_name, data, metadata={})
    queue(queue_name).push(data, metadata)
  end

  def self.retry_item(item)
    if (item.retries < max_retries)
      item.retries += 1
      item.last_tried_at = Time.now.to_f
      queue(item.origin_queue).push(item)
      raise ItemRetried
    else
      error_item(item)
    end
  end

  def self.error_item(item)
    item.fatal_error_at = Time.now.to_f
    error_queue.push(item)
    raise ItemErrored
  end

  def self.pause(queue_name)
    queue(queue_name).pause
  end

  def self.unpause(queue_name)
    queue(queue_name).unpause
  end

  def self.config(&block)
    initialize_if_necessary
    yield @config
  end

  def self.max_retries
    initialize_if_necessary
    @config.max_retries
  end

  def self.stat_timeout
    initialize_if_necessary
    @config.stat_timeout
  end

  def self.stat_timeout_seconds
    initialize_if_necessary
    @config.stat_timeout * 60
  end

  def self.watch(queue_name, &block)
    queue = queue(queue_name)
    while(true)
      item = queue.pop
      fix_binding(block)
      item.started_processing_at = Time.now.to_f

      begin
        block.call(item, self)
      rescue ItemRetried
        queue.add_retry_stat(item)
      rescue ItemErrored
        queue.add_error_stat(item)
      else
        item.finished_processing_at = Time.now.to_f
        queue.add_success_stat(item)
      end
    end
  end

  private def self.initialize_if_necessary
    @config ||= Config.new
  end

  # Hacky-hacky. I like the idea of calling retry_item(item) and
  # error_item(item)
  # directly from the watch block, but this seems ugly. There may be a better
  # way to do this.
  private def self.fix_binding(block)
    binding = block.binding
    binding.eval <<-HERE
      def retry_item(item)
        Timberline.retry_item(item)
        raise Timberline::ItemRetried
      end

      def error_item(item)
        Timberline.error_item(item)
        raise Timberline::ItemErrored
      end
    HERE
  end

  class ItemRetried < Exception
  end

  class ItemErrored < Exception
  end
end

Timberline.instance_variable_set("@queue_list", {})
