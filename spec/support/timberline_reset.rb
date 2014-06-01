module SpecSupport
  module TimberlineReset
    def self.clear_config
      Timberline.redis = nil
      Timberline.instance_variable_set("@config", nil)
      clear_test_db
      Timberline.redis = nil
    end

    # Use database 15 for testing, so we don't risk overwriting any data that's
    # actually useful
    def self.clear_test_db
      Timberline.config do |c|
        c.database = 15
      end
      Timberline.redis.flushdb
    end

  end
end
