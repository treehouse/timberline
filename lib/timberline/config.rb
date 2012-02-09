class Timberline
  class Config
    attr_accessor :database, :host, :port, :timeout, :password, :logger, :namespace, :max_retries

    def initialize
      if defined? TIMBERLINE_YAML
        if File.exists?(TIMBERLINE_YAML)
          load_from_yaml(TIMBERLINE_YAML)
        else
          raise "Specified Timberline config file #{TIMBERLINE_YAML} is not present."
        end
      elsif defined? RAILS_ROOT
        config_file = File.join(RAILS_ROOT, 'config', 'timberline.yaml')
        if File.exists?(config_file)
          load_from_yaml(config_file)
        end
      end
    end

    def namespace
      @namespace ||= 'timberline'
    end

    def max_retries
      @max_retries ||= 5
    end

    def redis_config
      config = {}

      { :db => database, :host => host, :port => port, :timeout => timeout, :password => password, :logger => logger }.each do |name, value|
        config[name] = value unless value.nil?
      end

      config
    end

    def load_from_yaml(filename)
      yaml_config = YAML.load_file(filename)
      ["database","host","port","timeout","password","logger","namespace"].each do |setting|
        self.instance_variable_set("@#{setting}", yaml_config[setting])
      end
    end
  end
end
