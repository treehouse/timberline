class Timberline
  class Queue
    attr_reader :queue_name, :read_timeout

    def initialize(queue_name, read_timeout= 0)
      @queue_name = queue_name
      @read_timeout = read_timeout
      @redis = Timberline.redis
      @redis.sadd "timberline_queue_names", queue_name
    end

    def delete!
      @redis.del @queue_name
      @redis.keys("#{@queue_name}:*").each do |key|
        @redis.del key
      end
      @redis.srem "timberline_queue_names", @queue_name
    end

    def length
      @redis.llen @queue_name
    end

    def pop
      block_while_paused

      br_tuple = @redis.brpop(@queue_name, read_timeout)
      envelope_string = br_tuple.nil? ? nil : br_tuple[1]
      if envelope_string.nil?
        nil
      else
        Envelope.from_json(envelope_string)
      end
    end

    def push(contents, metadata = {})
      case contents
      when Envelope
        @redis.lpush @queue_name, contents
      else
        @redis.lpush @queue_name, wrap(contents, metadata)
      end
    end

    def pause
      @redis[attr("paused")] = "true"
    end

    def unpause
      @redis[attr("paused")] = "false"
    end

    def paused?
      @redis[attr("paused")] == "true"
    end

    def attr(key)
      "#{@queue_name}:#{key}"
    end

    def number_errors
      Timberline.redis.xcard attr("error_stats")
    end

    def number_retries
      Timberline.redis.xcard attr("retry_stats")
    end

    def number_successes
      Timberline.redis.xcard attr("success_stats")
    end

    def add_retry_stat(item)
      add_stat_for_key(attr("retry_stats"), item)
    end

    def add_error_stat(item)
      add_stat_for_key(attr("success_stats"), item)
    end

    def add_success_stat(item)
      add_stat_for_key(attr("success_stats"), item)
    end

    private

    def add_stat_for_key(key, item)
      Timberline.redis.xadd key, item, Time.now + Timberline.stat_timeout_seconds
    end

    def next_id
      Timberline.redis.incr attr("id_seq")
    end

    def wrap(contents, metadata)
      envelope = Envelope.new
      envelope.contents = contents
      metadata.each do |key, value|
        envelope.send("#{key.to_s}=", value)
      end

      # default metadata
      envelope.item_id = next_id
      envelope.retries = 0
      envelope.submitted_at = Time.now.to_f
      envelope.origin_queue = @queue_name

      envelope
    end

    def block_while_paused
      while(self.paused?)
        sleep(1)
      end
    end
  end
end
