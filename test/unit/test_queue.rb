require 'test_helper'

describe Treeline::Queue do
  describe "newly instantiated" do
    before do
      Redis.new.flushall
      @queue = Treeline::Queue.new("test_queue")
    end

    it "saves the passed-in string as its queue name" do
       assert_equal "test_queue", @queue.queue_name
    end

    it "has a length of 0" do
       assert_equal 0, @queue.length
    end

    it "responds nil to a pop request" do
       assert_equal nil, @queue.pop
    end

    it "puts an item on the queue when that item is pushed" do
       test_item = "Test Queue Item"
       assert_equal 1, @queue.push(test_item)
    end
  end

  describe "with one item" do
    before do
      Redis.new.flushall
      @test_item = "Test Queue Item"
      @queue = Treeline::Queue.new("test_queue")
      @queue.push(@test_item)
    end

    it "has a length of 1" do
      assert_equal 1, @queue.length
    end

    it "responds to pop with the one item" do
      assert_equal @test_item, @queue.pop
    end

    it "responds nil to a second pop" do
       assert_equal @test_item, @queue.pop
       assert_equal nil, @queue.pop
    end
  end
end
