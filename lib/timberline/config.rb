require "cgi"

class Timberline
  # Object that manages Timberline configuration. Responsible for Redis configs
  # as well as Timberline-specific configuration values, like how many times an
  # item should be retried in a queue.
  #
  # @attr [Integer] database part of the redis configuration - index of the
  #   redis database to use
  # @attr [String] host part of the redis configuration - the hostname of the
  #   redis server
  # @attr [Integer] port part of the redis configuration - the port of the
  #   redis server
  # @attr [Integer] timeout part of the redis configuration - the timeout for
  #   the redis server
  # @attr [String] password part of the redis configuration - the password for
  #   the redis server
  # @attr [Logger] logger part of the redis configuration - the logger to use
  #   for the redis connection
  # @attr [String] namespace the redis namespace for the keys that timberline
  #   will create and manage
  # @attr [Integer] max_retries the number of times that an item on the queue
  #   should be allowed to retry itself before it is placed on the error queue
  # @attr [Integer] stat_timeout the number of minutes that stats will stay live
  #   in redis before they are expired
  # @attr [Array] sentinels a list of sentinel hosts that can be connected to
  #   for failover protection.
  #
  class Config
    attr_accessor :database, :host, :port, :timeout, :password, :log_job_result_stats,
                  :logger, :namespace, :max_retries, :stat_timeout, :sentinels

    # Attemps to load configuration from TIMBERLINE_YAML, if it exists.
    # Otherwise creates a default Config object.
    def initialize
      configure_via_yaml
      configure_via_env
    end

    # @return [String] the configured redis namespace, with a default of 'timberline'
    def namespace
      @namespace ||= 'timberline'
    end

    # @return [Integer] the configured maximum number of retries, with a default of 5
    def max_retries
      @max_retries ||= 5
    end

    # @return [Integer] the configured lifetime of stats (in minutes), with a default of 60
    def stat_timeout
      @stat_timeout ||= 60
    end

    # @return [Boolean] configuration setting for logging each job success or error in redis
    # created in response to max memory limit on redis queues in aws
    def log_job_result?
      @log_job_result_stats ||= false
    end

    # @return [{host: "x", port: 1}] list of sentinel server
    def sentinels
      @sentinels ||= []
    end

    # @return [Hash] a Redis-ready hash for use in instantiating a new redis object.
    def redis_config
      config = {}

      {
        db: database,
        host: host,
        port: port,
        timeout: timeout,
        password: password,
        logger: logger,
        sentinels: sentinels.empty? ? nil : sentinels
      }.each do |name, value|
        config[name] = value unless value.nil?
      end

      config
    end

    private

    def configure_via_yaml
      return unless defined? TIMBERLINE_YAML
      if File.exist?(TIMBERLINE_YAML)
        yaml = YAML.load_file(TIMBERLINE_YAML)
        load_from_yaml(yaml)
      else
        fail "Specified Timberline config file #{TIMBERLINE_YAML} is not present."
      end
    end

    def convert_if_int(val)
      # convert strings that only have integers in them to ints
      val.match(/\A[+-]?\d+\Z/) ? val.to_i : val
    end

    def configure_via_env
      return unless ENV.key?("TIMBERLINE_URL")

      uri = URI::Parser.new.parse(ENV["TIMBERLINE_URL"])
      fail "Must be a redis url, not #{uri.scheme.inspect}" unless uri.scheme == "redis"

      @host = uri.host
      @port = uri.port
      @database = convert_if_int(uri.path[1..-1])
      @password = uri.password

      params = uri.query.nil? ? {} : CGI.parse(uri.query)
      %w(timeout namespace stat_timeout max_retries).each do |setting|
        next unless params.key?(setting)
        instance_variable_set("@#{setting}", convert_if_int(params[setting][0]))
      end
      if params.key?("sentinel")
        params["sentinel"].each do |val|
          host, port = val.split(":")
          self.sentinels += [{ "host" => host, "port" => convert_if_int(port) }]
        end
      end
    end

    def load_from_yaml(yaml_config)
      fail "Missing yaml configs!" if yaml_config.nil?
      %w(database host port timeout password namespace sentinels stat_timeout max_retries).each do |setting|
        instance_variable_set("@#{setting}", yaml_config[setting])
      end
    end
  end
end
