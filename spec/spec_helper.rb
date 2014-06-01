require 'rspec'
require 'pry'

require File.expand_path("../../lib/timberline", __FILE__)

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec do |c|
    c.syntax = [:expect]
  end

  config.order = "random"

  config.after(:each) do
    SpecSupport::TimberlineReset.clear_config
  end
end
