require 'test_helper'

describe Timberline::Queue do
  describe "newly instantiated" do
    before do
      clear_test_db
      @queue = Timberline::Queue.new("test_queue")
    end

    it "saves the passed-in string as its queue name" do
      assert_equal "test_queue", @queue.queue_name
    end

    it "has a length of 0" do
      assert_equal 0, @queue.length
    end

    it "has a default read_timeout of 0" do
      assert_equal 0, @queue.read_timeout
    end

    it "responds nil to a pop request after the read_timeout occurs" do
      # Let's set the read_timeout to 1 in order for this test to return
      @queue.instance_variable_set("@read_timeout", 1)
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
      assert_kind_of Timberline::Envelope, data
      assert_equal test_item, data.contents
    end

    it "doesn't wrap an envelope that gets pushed in another envelope" do
      test_item = "Test Queue Item"
      env = Timberline::Envelope.new
      env.contents = test_item
      assert_equal 1, @queue.push(env)
      data = @queue.pop
      assert_kind_of Timberline::Envelope, data
      assert_equal test_item, data.contents
    end
  end

  describe "with one item" do
    before do
      clear_test_db
      @test_item = "Test Queue Item"
      @queue = Timberline::Queue.new("test_queue")
      @queue.push(@test_item)
    end

    it "has a length of 1" do
      assert_equal 1, @queue.length
    end

    it "responds to pop with the one item" do
      assert_equal @test_item, @queue.pop.contents
    end

    it "responds nil to a second pop" do
      # Let's set the read_timeout to 1 in order for this test to return
      @queue.instance_variable_set("@read_timeout", 1)
      assert_equal @test_item, @queue.pop.contents
      assert_equal nil, @queue.pop
    end
  end
end
