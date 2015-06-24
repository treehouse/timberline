require 'spec_helper'

describe Timberline::AnonymousWorker do
  describe "error_item works in block" do
    it "doesn't raise a error when #error_item is called" do
      queue = Timberline::Queue.new("foo_queue")
      queue.push("apple")

      expect do
        Timberline.watch("foo_queue") do |job|
          begin
            error_item(job)
          rescue Timberline::ItemErrored
            break
          end
        end
      end.to_not raise_error
      expect(queue.error_queue.length).to eq(1)
    end
  end
end
