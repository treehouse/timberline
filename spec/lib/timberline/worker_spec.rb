require 'spec_helper'

describe Timberline::Worker do

  describe '#logger' do
    it 'returns the Timberline logger' do
      expect(Timberline::Worker.new.logger).to eq Timberline.logger
    end
  end

end
