class Timberline
  class Queue
    attr_reader :queue_name, :read_timeout

    def initialize(queue_name, read_timeout= 0)
      @queue_name = queue_name
      @read_timeout = read_timeout
      @redis = Timberline.redis
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

    def push(item)
      case item
      when Envelope
        @redis.lpush @queue_name, item
      else
        @redis.lpush @queue_name, wrap(item)
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

    private

    def attr(key)
      "#{@queue_name}:#{key}"
    end

    def wrap(item)
      envelope = Envelope.new
      envelope.contents = item
      envelope
    end

    def block_while_paused
      while(self.paused?)
        sleep(1)
      end
    end
  end
end
