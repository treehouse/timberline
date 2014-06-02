module SpecSupport
  module FakeRails
    def self.create_fake_env
      fake_rails = OpenStruct.new(root: File.join(File.dirname(File.path(__FILE__)), "..", "fake_rails"), env: "development") 
      Object.send(:const_set, :Rails, fake_rails)
    end

    def self.create_fake_env_without_config
      fake_rails = OpenStruct.new(root: File.join(File.dirname(File.path(__FILE__)), "..", "gibberish"), env: "development") 
      Object.send(:const_set, :Rails, fake_rails)
    end

    def self.destroy_fake_env
      Object.send(:remove_const, :Rails)
    end
  end
end
