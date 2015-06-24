require 'spec_helper'

describe Timberline::AnonymousWorker do
  describe "error_item works in block" do
    it "doesn't raise a error when #error_item is called" do
      queue = Timberline::Queue.new("foo_queue")
      queue.push("apple")

      expect do
        Timberline.watch("foo_queue") {|job| error_item(job) }
      end.to_not raise_error
    end
  end
end
