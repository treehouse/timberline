require_relative '../test_helper'

describe Timberline do
  describe "Freshly set up" do
    before do
      reset_timberline
    end

    it "creates a new queue when asked if it doesn't exist" do
      queue = Timberline.queue("test_queue")
      assert_kind_of Timberline::Queue, queue
      assert_equal queue, Timberline.instance_variable_get("@queue_list")["test_queue"]
    end

    it "doesn't create a new queue if a queue by the same name already exists" do
      queue = Timberline.queue("test_queue")
      new_queue = Timberline.queue("test_queue")
      assert_equal queue, new_queue
    end

    it "creates a new queue as necessary when 'push' is called and pushes the item" do
      Timberline.push("test_queue", "Howdy kids.")
      queue = Timberline.queue("test_queue")
      assert_equal 1, queue.length
      assert_equal "Howdy kids.", queue.pop.contents
    end

    it "logs the existence of the queue so that other managers can see it" do
      queue = Timberline.queue("test_queue")
      assert_equal 1, Timberline.all_queues.size
      assert_equal "test_queue", Timberline.all_queues.first.queue_name
    end

    it "saves a passed-in redis namespace" do
      redis = Redis.new
      redisns = Redis::Namespace.new("timberline", redis)
      Timberline.redis = redisns
      assert_equal redisns, Timberline.redis
    end

    it "Converts a standard redis server into a namespace" do
      redis = Redis.new
      Timberline.redis = redis
      assert_equal Redis::Namespace, Timberline.redis.class
      assert_equal redis, Timberline.redis.instance_variable_get("@redis")
    end

    it "generates a redis namespace on request if one isn't present" do
      assert_equal Redis::Namespace, Timberline.redis.class
    end

    it "uses a default namespace of 'timberline'" do
      assert_equal "timberline", Timberline.redis.namespace
    end

    it "can be configured" do
      Timberline.config do |c|
        c.database = 3 
      end

      assert_equal 3, Timberline.instance_variable_get("@config").database
    end

    it "uses a pre-defined namespace name if configured" do
      Timberline.config do |c|
        c.namespace = "skyline"
      end

      assert_equal "skyline", Timberline.redis.namespace
    end

    it "properly configures Redis" do
      @logger = Logger.new STDERR
      Timberline.config do |c|
        c.host = "localhost"
        c.timeout = 10
        c.database = 3 
        c.logger = @logger
      end

      redis = Timberline.redis

      assert_equal "localhost", redis.client.host
      assert_equal 10, redis.client.timeout
      assert_equal 3, redis.client.db
      assert_equal @logger, redis.client.logger

    end

    it "allows you to retry a job that has failed" do
      Timberline.push("test_queue", "Howdy kids.")
      queue = Timberline.queue("test_queue")
      data = queue.pop

      assert_equal 0, queue.length

      assert_raises Timberline::ItemRetried do
        Timberline.retry_item(data)
      end

      assert_equal 1, queue.length

      data = queue.pop
      assert_equal 1, data.retries
      assert_kind_of Time, Time.at(data.last_tried_at)
    end

    it "will continue retrying until we pass the max retries (defaults to 5)" do
      Timberline.push("test_queue", "Howdy kids.")
      queue = Timberline.queue("test_queue")
      data = queue.pop

      5.times do |i|
        assert_raises Timberline::ItemRetried do
          Timberline.retry_item(data)
        end
        assert_equal 1, queue.length
        data = queue.pop
        assert_equal i + 1, data.retries
      end

      assert_raises Timberline::ItemErrored do
        Timberline.retry_item(data)
      end
      assert_equal 0, queue.length
      assert_equal 1, Timberline.error_queue.length
    end

    it "will allow you to directly error out a job" do
      Timberline.push("test_queue", "Howdy kids.")
      queue = Timberline.queue("test_queue")
      data = queue.pop

      assert_raises Timberline::ItemErrored do
        Timberline.error_item(data)
      end
      assert_equal 1, Timberline.error_queue.length
      data = Timberline.error_queue.pop
      assert_kind_of Time, Time.at(data.fatal_error_at)
    end

  end
end
