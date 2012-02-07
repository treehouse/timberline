require 'test/unit'

require 'partial_minispec'

# include the gem
require 'treeline'

# Use database 15 for testing, so we don't risk overwriting any data that's
# actually useful
def clear_test_db
  Treeline.config do |c|
    c.database = 15
  end
  Treeline.redis.flushdb
end
