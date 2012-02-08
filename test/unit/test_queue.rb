require 'test_helper'

describe Treeline::Queue do
  describe "newly instantiated" do
    before do
      clear_test_db
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

    it "wraps an item in an envelope when that item is pushed" do
      test_item = "Test Queue Item"
      assert_equal 1, @queue.push(test_item)
      data = @queue.pop
      assert_equal Treeline::Envelope, data.class
      assert_equal test_item, data.contents
    end
  end

  describe "with one item" do
    before do
      clear_test_db
      @test_item = "Test Queue Item"
      @queue = Treeline::Queue.new("test_queue")
      @queue.push(@test_item)
    end

    it "has a length of 1" do
      assert_equal 1, @queue.length
    end

    it "responds to pop with the one item" do
      assert_equal @test_item, @queue.pop.contents
    end

    it "responds nil to a second pop" do
      assert_equal @test_item, @queue.pop.contents
      assert_equal nil, @queue.pop
    end
  end
end