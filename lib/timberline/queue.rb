class Timberline
  class Queue
    attr_reader :queue_name, :read_timeout

    def initialize(queue_name, read_timeout: 0, hidden: false)
      if queue_name.nil?
        raise ArgumentError.new("Queue name must be provided.")
      end
      @queue_name = queue_name
      @read_timeout = read_timeout
      @redis = Timberline.redis
      unless hidden
        @redis.sadd "timberline_queue_names", queue_name
      end
    end

    def delete
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

    def average_execution_time
      successes = Timberline.redis.xmembers(attr("success_stats")).map { |item| Envelope.from_json(item)}
      times = successes.map do |item|
        if item.finished_processing_at
          item.finished_processing_at.to_f - item.started_processing_at.to_f
        elsif item.fatal_error_at
          item.fatal_error_at.to_f - item.started_processing_at.to_f
        else
          nil
        end
      end
      times.reject! { |t| t.nil? }
      if times.size == 0
        0
      else
        times.inject(0, :+) / times.size.to_f
      end
    end

    def retry_item(item)
      if (item.retries < Timberline.max_retries)
        item.retries += 1
        item.last_tried_at = Time.now.to_f
        add_retry_stat(item)
        push(item)
      else
        error_item(item)
      end
    end

    def error_item(item)
      item.fatal_error_at = Time.now.to_f
      add_error_stat(item)
      self.error_queue.push(item)
    end

    def add_retry_stat(item)
      add_stat_for_key(attr("retry_stats"), item)
    end

    def add_error_stat(item)
      add_stat_for_key(attr("error_stats"), item)
    end

    def add_success_stat(item)
      add_stat_for_key(attr("success_stats"), item)
    rescue Exception => e
      $stderr.puts "Success Stat Error: #{e.inspect}, Item: #{item.inspect}"
    end

    def error_queue
      @error_queue ||= Timberline.queue(attr("errors"), hidden: true)
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
