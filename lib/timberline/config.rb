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
      elsif defined? Rails.root
        config_file = File.join(Rails.root, 'config', 'timberline.yaml')
        if File.exists?(config_file)
          configs = YAML.load_file(config_file)
          config = configs[Rails.env]
          load_from_yaml(config)
        end
      end

      # load defaults
      @namespace  ||= 'timberline'
      @max_retries ||= 5
      @stat_timeout ||= 60
    end

    def redis_config
      config = {}

      { :db => database, :host => host, :port => port, :timeout => timeout, :password => password, :logger => logger }.each do |name, value|
        config[name] = value unless value.nil?
      end

      config
    end

    def load_from_yaml(yaml_config)
      raise "Missing yaml configs!" if yaml_config.nil?
      ["database","host","port","timeout","password","logger","namespace"].each do |setting|
        self.instance_variable_set("@#{setting}", yaml_config[setting])
      end
    end
  end
end
