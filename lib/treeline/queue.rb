module Treeline
  class Queue
    attr_accessor :queue_name

    def initialize(queue_name)
      @queue_name = queue_name
      @redis = Redis.new
    end

    def length
      @redis.llen @queue_name
    end

    def pop
      @redis.rpop @queue_name
    end

    def push(item)
      @redis.lpush @queue_name, item
    end

  end
end
