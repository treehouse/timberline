require 'test_helper'

describe Treeline do
  before do
    Treeline.redis = nil
  end

  it "saves a passed-in redis server" do
    redis = Redis.new
    Treeline.redis = redis
    assert_equal redis, Treeline.redis
  end

  it "generates a redis on request if one isn't present" do
    assert_equal Redis, Treeline.redis.class
  end

  it "can be configured" do
    Treeline.config do |c|
      c.database = 15
    end

    assert_equal 15, Treeline::Config.database
  end

  it "builds and uses a proper config hash for Redis" do
    @logger = Logger.new STDOUT
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

  end
end
