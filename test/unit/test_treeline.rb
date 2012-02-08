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

  it "saves a passed-in redis server" do
    redis = Redis.new
    Treeline.redis = redis
    assert_equal redis, Treeline.redis
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

    assert_equal 3, Treeline::Config.database
  end

  it "uses a pre-defined namespace name if configured" do
    Treeline.config do |c|
      c.namespace = "skyline"
    end

    assert_equal "skyline", Treeline.redis.namespace
  end

  it "builds and uses a proper config hash for Redis" do
    @logger = Logger.new STDERR
    Treeline.config do |c|
      c.host = "localhost"
      c.port = 12345
      c.timeout = 10
      c.password = "foo"
      c.database = 15
      c.logger = @logger
    end

    config = Treeline::Config.redis_config

    assert_equal "localhost", config[:host]
    assert_equal 12345, config[:port]
    assert_equal 10, config[:timeout]
    assert_equal "foo", config[:password]
    assert_equal 15, config[:db]
    assert_equal @logger, config[:logger]

    # reset the parameters that, if changed from defaults, cause Redis not to be
    # able to connect
    Treeline.config do |c|
      c.password = nil
      c.port = nil
    end

    redis = Treeline.redis

    assert_equal "localhost", redis.client.host
    assert_equal 10, redis.client.timeout
    assert_equal 15, redis.client.db
    assert_equal @logger, redis.client.logger

  end
end
