module SpecSupport
  module TimberlineYaml
    def self.load_constant
      config_file = File.join(File.dirname(File.path(__FILE__)), "..", "config", "test_config.yaml") 
      Object.send(:const_set, :TIMBERLINE_YAML, config_file)
    end

    def self.load_constant_for_missing_file
      config_file = File.join(File.dirname(File.path(__FILE__)), "..", "config", "party_config.yaml") 
      Object.send(:const_set, :TIMBERLINE_YAML, config_file)
    end

    def self.destroy_constant
      Object.send(:remove_const, :TIMBERLINE_YAML)
    end
  end
end
