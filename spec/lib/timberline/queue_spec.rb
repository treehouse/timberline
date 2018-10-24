require 'spec_helper'

describe Timberline::Queue do
  describe "#initialize" do
    it "raises an ArgumentError if no queue_name is provided" do
      expect { Timberline::Queue.new(nil) }.to raise_error(ArgumentError)
    end

    it "loads a default read_timeout of 0" do
      expect(Timberline::Queue.new("fritters").read_timeout).to eq(0)
    end

    it "allows you to override the default read_timeout" do
      expect(Timberline::Queue.new("fritters", read_timeout: 50).read_timeout).to eq(50)
    end

    context "if the queue is marked as hidden" do
      before do
        Timberline::Queue.new("fritters", hidden: true)
      end

      it "Doesn't add it to the queue listing in Timberline" do
        expect(Timberline.all_queues.map { |q| q.queue_name }).not_to include("fritters")
      end
    end

    it "adds the queue's name to the Timberline queue listing" do
      Timberline::Queue.new("fritters")
      expect(Timberline.all_queues.map { |q| q.queue_name }).to include("fritters")
    end
  end

  describe "#delete" do
    subject { Timberline::Queue.new("fritters") }

    before do
      subject.delete
    end

    it "removes the queue from redis" do
      expect(Timberline.redis.get("fritters")).to be_nil 
    end

    it "removes all of the queue's attributes from redis" do
      expect(Timberline.redis.get("fritters:*")).to be_nil
    end

    it "removes the queue from the Timberline queue listing" do
      expect(Timberline.all_queues.map { |q| q.queue_name }).not_to include("fritters")
    end
  end

  describe "#pop" do
    subject { Timberline::Queue.new("fritters") }
    before { subject.push("apple") }

    it "will block if the queue is paused" do
      expect(subject).to receive(:block_while_paused)
      subject.pop
    end

    it "will return a Timberline::Envelope object" do
      expect(subject.pop).to be_a Timberline::Envelope
    end
  end

  describe "#push" do
    subject { Timberline::Queue.new("fritters") }

    it "returns the current size of the queue when you push" do
      expect(subject.push("Test")).to be_a Numeric
    end

    it "puts an item on the queue when you push" do
      subject.push("Test")
      expect(subject.length).to eq(1)
    end
    
    it "properly formats data so it can be popped successfully" do
      subject.push("Test")
      expect(subject.pop).to be_a Timberline::Envelope
    end
  end

  describe "#pause" do
    subject { Timberline::Queue.new("fritters") }

    before do
      subject.pause
    end

    it "puts the queue in paused mode" do
      expect(subject).to be_paused
    end
  end

  describe "#unpause" do
    subject { Timberline::Queue.new("fritters") }

    before do
      subject.pause
      subject.unpause
    end

    it "unpauses the queue" do
      expect(subject).not_to be_paused
    end

  end

  describe "#error_item" do
    subject    { Timberline::Queue.new("fritters") }
    let(:item) { subject.push("apple"); subject.pop }

    before do
      Timberline.configure do |c|
        c.log_job_result_stats = true
      end
      subject.error_item(item)
    end

    it "updates the fatal_error_at timestamp for the item" do
      expect(item.fatal_error_at).not_to be_nil
    end

    it "puts the item on the queue's error queue" do
      expect(subject.error_queue.length).to eq(1)
    end

    it "adds an error statistic" do
      expect(subject.number_errors).to eq(1)
    end
  end

  describe "#retry_item" do
    subject    { Timberline::Queue.new("fritters") }
    let(:item) { subject.push("apple"); subject.pop }

    context "when the item hasn't been retried before" do
      before do
        Timberline.configure do |c|
          c.log_job_result_stats = true
        end
        subject.retry_item(item)
      end

      it "adds a retry statistic" do
        expect(subject.number_retries).to eq(1)
      end

      it "puts the item back on the queue" do
        expect(subject.length).to eq(1)
      end

      it "updates the last_tried_at property on the item" do
        expect(item.last_tried_at).not_to be_nil
      end
    end

    context "when the item has been retried before" do
      before do
        Timberline.configure do |c|
          c.log_job_result_stats = true
        end
        item.retries = 3
        subject.retry_item(item)
      end

      it "adds a retry statistic" do
        expect(subject.number_retries).to eq(1)
      end

      it "puts the item back on the queue" do
        expect(subject.length).to eq(1)
      end

      it "updates the last_tried_at property on the item" do
        expect(item.last_tried_at).not_to be_nil
      end
    end

    context "when the item has been retried the maximum number of times" do
      before do
        item.retries = 5
      end

      it "defers to #error_item" do
        expect(subject).to receive(:error_item).with(item)
        subject.retry_item(item)
      end
    end
  end
end
