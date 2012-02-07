class Treeline
  class Queue
    attr_reader :queue_name

    def initialize(queue_name)
      @queue_name = queue_name
      @redis = Treeline.redis
    end

    def length
      @redis.llen @queue_name
    end

    def pop
      envelope_string = @redis.rpop @queue_name
      if envelope_string.nil?
        nil
      else
        Envelope.from_json(envelope_string)
      end
    end

    def push(item)
      @redis.lpush @queue_name, wrap(item)
    end

    private

    def wrap(item)
      envelope = Envelope.new
      envelope.contents = item
      envelope
    end

  end
end
