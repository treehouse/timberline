require 'test_helper'

describe Treeline do
  before do
    # Reset the singletons
    Treeline.redis = nil
    Treeline.config do |c|
      c.database = nil
      c.host = nil
      c.port = nil
      c.timeout = nil
      c.password = nil
      c.logger = nil
      c.namespace = nil
    end
  end

  it "saves a passed-in redis namespace" do
    redis = Redis.new
    redisns = Redis::Namespace.new("treeline", redis)
    Treeline.redis = redisns
    assert_equal redisns, Treeline.redis
  end

  it "Converts a standard redis server into a namespace" do
    redis = Redis.new
    Treeline.redis = redis
    assert_equal Redis::Namespace, Treeline.redis.class
    assert_equal redis, Treeline.redis.instance_variable_get("@redis")
  end

  it "generates a redis namespace on request if one isn't present" do
    assert_equal Redis::Namespace, Treeline.redis.class
  end

  it "uses a default namespace of 'treeline'" do
    assert_equal "treeline", Treeline.redis.namespace
  end

  it "can be configured" do
    Treeline.config do |c|
      c.database = 3 
    end

    assert_equal 3, Treeline.instance_variable_get("@config").database
  end

  it "uses a pre-defined namespace name if configured" do
    Treeline.config do |c|
      c.namespace = "skyline"
    end

    assert_equal "skyline", Treeline.redis.namespace
  end

  it "properly configures Redis" do
    @logger = Logger.new STDERR
    Treeline.config do |c|
      c.host = "localhost"
      c.timeout = 10
      c.database = 3 
      c.logger = @logger
    end

    redis = Treeline.redis

    assert_equal "localhost", redis.client.host
    assert_equal 10, redis.client.timeout
    assert_equal 3, redis.client.db
    assert_equal @logger, redis.client.logger

  end
end
