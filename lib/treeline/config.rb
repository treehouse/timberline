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
  end
end
