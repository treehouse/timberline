class Treeline
  class Config
    attr_accessor :database, :host, :port, :timeout, :password, :logger, :namespace

    def initialize
      if defined? TREELINE_YAML
        if File.exists?(TREELINE_YAML)
          load_from_yaml(TREELINE_YAML)
        else
          raise "Specified Treeline config file is not present, check TREELINE_YAML."
        end
      elsif defined? RAILS_ROOT
        config_file = File.join(RAILS_ROOT, 'config', 'treeline.yaml')
        if File.exists?(config_file)
          load_from_yaml(config_file)
        end
      end
    end

    def namespace
      @namespace ||= 'treeline'
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
