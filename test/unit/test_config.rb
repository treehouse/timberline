require 'test_helper'

describe Treeline::Config do
  before do
    @config = Treeline::Config.new
  end

  it "builds a proper config hash for Redis" do
    @logger = Logger.new STDERR

    @config.host = "localhost"
    @config.port = 12345
    @config.timeout = 10
    @config.password = "foo"
    @config.database = 3
    @config.logger = @logger

    config = @config.redis_config

    assert_equal "localhost", config[:host]
    assert_equal 12345, config[:port]
    assert_equal 10, config[:timeout]
    assert_equal "foo", config[:password]
    assert_equal 3, config[:db]
    assert_equal @logger, config[:logger]

  end

  it "reads configuration from a YAML config file" do
    base_dir = File.dirname(File.path(__FILE__))
    yaml_file = File.join(base_dir, "..", "test_config.yaml")
    @config.load_from_yaml(yaml_file)
    assert_equal "localhost", @config.host
    assert_equal 12345, @config.port
    assert_equal 10, @config.timeout
    assert_equal "foo", @config.password
    assert_equal 3, @config.database
    assert_equal "treecurve", @config.namespace
  end

end
