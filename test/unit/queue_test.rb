require_relative '../test_helper'

class QueueTest < Test::Unit::TestCase
  a "newly instantiated Queue" do
    before do
      clear_test_db
      @queue = Timberline::Queue.new("test_queue")
    end

    it "saves the passed-in string as its queue name" do
      assert_equal "test_queue", @queue.queue_name
    end

    it "saves its existence in timberline_queue_names" do
      assert_equal true, Timberline.redis.sismember("timberline_queue_names", "test_queue")
    end

    it "has a length of 0" do
      assert_equal 0, @queue.length
    end

    it "starts in an unpaused state" do
      assert_equal false, @queue.paused?
    end

    it "allows itself to be paused and unpaused" do
      @queue.pause
      assert_equal true, @queue.paused?
      @queue.unpause
      assert_equal false, @queue.paused?
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

    it "removes everything associated with the queue when delete! is called" do
      test_item = "Test Queue Item"
      assert_equal 1, @queue.push(test_item)
      Timberline.redis[@queue.attr("test")] = "test"
      Timberline.redis[@queue.attr("foo")] = "foo"
      Timberline.redis[@queue.attr("bar")] = "bar"

      @queue.delete!
      assert_equal nil, Timberline.redis[@queue.attr("test")]
      assert_equal nil, Timberline.redis[@queue.attr("test")]
      assert_equal nil, Timberline.redis[@queue.attr("test")]
      assert_equal nil, Timberline.redis[@queue.queue_name]
      assert_equal false, Timberline.redis.sismember("timberline_queue_names","test_queue")
    end

    it "uses any passed-in metadata to push when building the envelope" do
      @queue.push("Howdy kids.", { :special_notes => "Super-awesome."})
      assert_equal 1, @queue.length
      data = @queue.pop
      assert_equal "Howdy kids.", data.contents
      assert_equal "Super-awesome.", data.special_notes
    end

  end

  a "Queue with one item" do
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
