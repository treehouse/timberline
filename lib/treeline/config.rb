class Treeline
  class Config
    attr_accessor :database, :host, :port, :timeout, :password, :logger, :namespace

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
