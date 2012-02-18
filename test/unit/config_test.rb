require 'test_helper'

class ConfigTest < Test::Unit::TestCase
  context "Without any preset YAML configs" do
    setup do
      @config = Timberline::Config.new
    end

    should "build a proper config hash for Redis" do
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

    should "reads configuration from a YAML config file" do
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

  context "when in a Rails app without a config file" do
    setup do
      Object::RAILS_ROOT = File.join(File.dirname(File.path(__FILE__)), "..", "gibberish")
      @config = Timberline::Config.new
    end

    teardown do
      Object.send(:remove_const, :RAILS_ROOT)
    end

    should "load successfully without any configs." do
      ["database","host","port","timeout","password","logger"].each do |setting|
        assert_equal nil, @config.instance_variable_get("@#{setting}")
      end

      # check defaults
      assert_equal "timberline", @config.namespace
      assert_equal 5, @config.max_retries
      assert_equal 60, @config.stat_timeout
    end
  end

  context "when in a Rails app with a config file" do
    setup do
      Object::RAILS_ROOT = File.join(File.dirname(File.path(__FILE__)), "..", "fake_rails")
      @config = Timberline::Config.new
    end

    teardown do
      Object.send(:remove_const, :RAILS_ROOT)
    end

    should "load the config/timberline.yaml file" do
      assert_equal "localhost", @config.host
      assert_equal 12345, @config.port
      assert_equal 10, @config.timeout
      assert_equal "foo", @config.password
      assert_equal 3, @config.database
      assert_equal "treecurve", @config.namespace
    end
  end

  context "when TIMBERLINE_YAML is defined" do
    setup do
      Object::TIMBERLINE_YAML = File.join(File.dirname(File.path(__FILE__)), "..", "test_config.yaml")
      @config = Timberline::Config.new
    end

    teardown do
      Object.send(:remove_const, :TIMBERLINE_YAML)
    end

    should "load the specified yaml file" do
      assert_equal "localhost", @config.host
      assert_equal 12345, @config.port
      assert_equal 10, @config.timeout
      assert_equal "foo", @config.password
      assert_equal 3, @config.database
      assert_equal "treecurve", @config.namespace
    end
  end

  context "when TIMBERLINE_YAML is defined, but doesn't exist" do
    setup do
      Object::TIMBERLINE_YAML = File.join(File.dirname(File.path(__FILE__)), "..", "fake_config.yaml")
    end

    teardown do
      Object.send(:remove_const, :TIMBERLINE_YAML)
    end

    should "raise an exception" do
      assert_raises RuntimeError do 
        @config = Timberline::Config.new
      end
    end
  end
end
