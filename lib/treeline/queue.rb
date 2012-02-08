class Treeline
  class Queue
    attr_reader :queue_name, :read_timeout

    def initialize(queue_name, read_timeout= 0)
      @queue_name = queue_name
      @read_timeout = read_timeout
      @redis = Treeline.redis
    end

    def length
      @redis.llen @queue_name
    end

    def pop
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

    private

    def wrap(item)
      envelope = Envelope.new
      envelope.contents = item
      envelope
    end
  end
end
