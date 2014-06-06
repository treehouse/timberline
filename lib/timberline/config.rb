class Timberline
  class Config
    attr_accessor :database, :host, :port, :timeout, :password, :logger, :namespace, :max_retries, :stat_timeout

    def initialize
      if defined? TIMBERLINE_YAML
        if File.exists?(TIMBERLINE_YAML)
          yaml = YAML.load_file(TIMBERLINE_YAML)
          load_from_yaml(yaml)
        else
          raise "Specified Timberline config file #{TIMBERLINE_YAML} is not present."
        end
      end
    end

    def namespace
      @namespace ||= 'timberline'
    end

    def max_retries
      @max_retries ||= 5
    end

    def stat_timeout
      @stat_timeout ||= 60
    end

    def redis_config
      config = {}

      { db: database, host: host, port: port, timeout: timeout, password: password, logger: logger }.each do |name, value|
        config[name] = value unless value.nil?
      end

      config
    end

  private
    def load_from_yaml(yaml_config)
      raise "Missing yaml configs!" if yaml_config.nil?
      ["database","host","port","timeout","password","logger","namespace"].each do |setting|
        self.instance_variable_set("@#{setting}", yaml_config[setting])
      end
    end
  end
end
