require 'minitest/autorun'
require 'ostruct'

# include the gem
require 'timberline'

def reset_timberline
  Timberline.redis = nil
  Timberline.instance_variable_set("@config", nil)
  clear_test_db
  Timberline.redis = nil
  Timberline.instance_variable_set("@queue_list", {})
end

# Use database 15 for testing, so we don't risk overwriting any data that's
# actually useful
def clear_test_db
  Timberline.config do |c|
    c.database = 15
  end
  Timberline.redis.flushdb
end

