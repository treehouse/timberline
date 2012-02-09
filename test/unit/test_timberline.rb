require 'test_helper'

describe Timberline do
  before do
    # Reset the singleton
    Timberline.redis = nil
    Timberline.instance_variable_set("@config", nil)
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
end
