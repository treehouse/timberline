require 'test_helper'

describe Treeline::QueueManager do
  describe "newly instantiated" do
    before do
      clear_test_db
      @qm = Treeline::QueueManager.new
    end

    it "has an empty queue list" do
      assert_equal 0, @qm.queue_list.size
    end

    it "instantiates an error_queue" do
      assert_kind_of Treeline::Queue, @qm.error_queue
      assert_equal "treeline_errors", @qm.error_queue.queue_name
    end

    it "creates a new queue when asked if it doesn't exist" do
      queue = @qm.queue("test_queue")
      assert_kind_of Treeline::Queue, queue
      assert_equal 1, @qm.queue_list.size
      assert_equal queue, @qm.queue_list["test_queue"]
    end

    it "doesn't create a new queue if a queue by the same name already exists" do
      queue = @qm.queue("test_queue")
      new_queue = @qm.queue("test_queue")
      assert_equal queue, new_queue
      assert_equal 1, @qm.queue_list.size
    end

    it "creates a new queue as necessary when 'push' is called and pushes the item" do
      @qm.push("test_queue", "Howdy kids.")
      assert_equal 1, @qm.queue_list.size
      queue = @qm.queue("test_queue")
      assert_equal 1, queue.length
      assert_equal "Howdy kids.", queue.pop.contents
    end

    it "uses any passed-in metadata to push when building the envelope" do
      @qm.push("test_queue", "Howdy kids.", { :special_notes => "Super-awesome."})
      queue = @qm.queue("test_queue")
      assert_equal 1, queue.length
      data = queue.pop
      assert_equal "Howdy kids.", data.contents
      assert_equal "Super-awesome.", data.special_notes
    end

    it "includes some default information in the metadata" do
      @qm.push("test_queue", "Howdy kids.")
      queue = @qm.queue("test_queue")
      data = queue.pop
      assert_equal "Howdy kids.", data.contents
      assert_kind_of DateTime, DateTime.parse(data.submitted_at)
      assert_equal "test_queue", data.origin_queue
      assert_equal 0, data.retries
      assert_equal 1, data.job_id
    end

    it "allows you to retry a job that has failed" do
      @qm.push("test_queue", "Howdy kids.")
      queue = @qm.queue("test_queue")
      data = queue.pop

      assert_equal 0, queue.length
      
      @qm.retry_job(data)

      assert_equal 1, queue.length

      data = queue.pop
      assert_equal 1, data.retries
      assert_kind_of DateTime, DateTime.parse(data.last_tried_at)
    end

    it "will continue retrying until we pass the max retries (defaults to 5)" do
      @qm.push("test_queue", "Howdy kids.")
      queue = @qm.queue("test_queue")
      data = queue.pop

      5.times do |i|
        @qm.retry_job(data)
        assert_equal 1, queue.length
        data = queue.pop
        assert_equal i + 1, data.retries
      end

      @qm.retry_job(data)
      assert_equal 0, queue.length
      assert_equal 1, @qm.error_queue.length
    end

    it "will allow you to directly error out a job" do
      @qm.push("test_queue", "Howdy kids.")
      queue = @qm.queue("test_queue")
      data = queue.pop

      @qm.error_job(data)
      assert_equal 1, @qm.error_queue.length
      data = @qm.error_queue.pop
      assert_kind_of DateTime, DateTime.parse(data.fatal_error_at)
    end

    it "will allow you to watch a queue" do
      @qm.push("test_queue", "Howdy kids.")
      
      assert_raises RuntimeError do
        @qm.watch "test_queue" do |job|
          if "Howdy kids." == job.contents
            raise "This works."
          end
        end
      end

      assert_equal 0, @qm.queue("test_queue").length
    end

    it "will allow you to retry from a queue watcher" do
      @qm.push("test_queue", "Howdy kids.")

      assert_raises RuntimeError do
        @qm.watch "test_queue" do |job|
          if "Howdy kids." == job.contents
            retry_job job
            raise "Job retried."
          end
        end
      end

      assert_equal 1, @qm.queue("test_queue").length
      data = @qm.queue("test_queue").pop
      assert_equal 1, data.retries
    end

    it "will allow you to error from a queue watcher" do
      @qm.push("test_queue", "Howdy kids.")

      assert_raises RuntimeError do
        @qm.watch "test_queue" do |job|
          if "Howdy kids." == job.contents
            error_job job
            raise "Job errored."
          end
        end
      end

      assert_equal 1, @qm.error_queue.length
      data = @qm.error_queue.pop
      assert_kind_of DateTime, DateTime.parse(data.fatal_error_at)
    end
  end

end
