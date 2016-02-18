require 'spec_helper'

describe Timberline do
  describe ".redis=" do
    context "if Timberline hasn't been configured yet" do
      before { Timberline.redis = nil }

      it "initializes a new configuration object" do
        expect(Timberline.config).not_to be_nil  
      end
    end

    context "if the argument is a Redis instance" do
      before { Timberline.redis = Redis.new }

      it "wraps the server in a namespace" do
        expect(Timberline.redis).to be_a Redis::Namespace
      end
    end

    context "if the argument is a Redis::Namespace instance" do
      let(:namespace) { Redis::Namespace.new("fritters", redis: Redis.new) }
      before { Timberline.redis = namespace }

      it "accepts the namespace as-is" do
        expect(Timberline.redis).to eq(namespace)
      end
    end

    context "if the argument is nil" do
      before do
        Timberline.redis = Redis.new
        Timberline.redis = nil
      end
      
      it "clears out the existing redis server" do
        expect(Timberline.instance_variable_get("@redis")).to be_nil
      end
    end

    context "if the argument is not an instance of nil, Redis, or Redis::Namespace" do
      it "raises an exception" do
        expect { Timberline.redis = "this isn't redis" }.to raise_error(StandardError)
      end
    end
  end

  describe ".redis" do
    context "if Timberline hasn't been configured yet" do
      before { Timberline.redis }

      it "initializes a new configuration object" do
        expect(Timberline.config).not_to be_nil  
      end

      it "initializes a default redis server" do
        expect(Timberline.redis).not_to be_nil
      end
    end

    context "if Timberline has already had a redis server provided" do
      let(:namespace) { Redis::Namespace.new("fritters", redis: Redis.new) }
      before { Timberline.redis = namespace }

      it "returns that server" do
        expect(Timberline.redis).to eq(namespace)
      end
    end
  end

  describe ".all_queues" do
    context "when there are no queues" do
      before { allow(Timberline.redis).to receive(:smembers) { [] } }

      it "returns an empty list" do
        expect(Timberline.all_queues).to eq([])
      end
    end

    context "when there are some queues" do
      before { allow(Timberline.redis).to receive(:smembers) { %w(my_queue your_queue) } }

      it "returns a list of appropriate size" do
        expect(Timberline.all_queues.size).to eq(2)
      end

      it "returns a list of Queue objects" do
        expect(Timberline.all_queues.first).to be_a Timberline::Queue
        expect(Timberline.all_queues.last).to be_a Timberline::Queue
      end
    end
  end

  describe ".queue" do
    it "returns a Timberline::Queue" do
      expect(Timberline.queue("fritters")).to be_a Timberline::Queue
    end

    it "returns a queue with the appropriate name" do
      expect(Timberline.queue("fritters").queue_name).to eq("fritters")
    end
  end

  describe ".push" do
    let(:data) { "some data" }
    let(:metadata) { { meta: :data } }

    it "uses the #push method on the specified queue" do
      expect_any_instance_of(Timberline::Queue).to receive(:push).with(data, metadata)
      Timberline.push("fritters", data, metadata)
    end
  end

  describe ".retry_item" do
    let(:queue) { Timberline.queue("test_queue") }
    let(:item) { Timberline.push(queue.queue_name, "Howdy kids."); queue.pop }

    context "when the item has not yet been retried" do
      before { Timberline.retry_item(item) }

      it "puts the item back on the queue" do
        expect(queue.length).to eq(1)
      end

      it "updates the retry count on the item" do
        expect(item.retries).to eq(1)
      end
    end

    context "when the item has been retried less than the maximum number of times" do
      before do
        Timberline.configure do |c|
          c.max_retries = 5
        end

        item.retries = 3

        Timberline.retry_item(item)
      end

      it "puts the item back on the queue" do
        expect(queue.length).to eq(1)
      end

      it "updates the retry count on the item" do
        expect(item.retries).to eq(4)
      end
    end

    context "when the item has been retried the maximum number of times" do
      before do
        Timberline.configure do |c|
          c.max_retries = 5
        end

        item.retries = 5
      end

      it "passes the item on to the origin queue for retry" do
        expect_any_instance_of(Timberline::Queue).to receive(:retry_item).with(item)
        Timberline.retry_item(item)
      end
    end
  end

  describe ".error_item" do
    let(:queue) { Timberline.queue("test_queue") }
    let(:error_queue) { queue.error_queue }
    let(:item) { Timberline.push(queue.queue_name, "Howdy kids."); queue.pop }

    it "passes the item on to the queue for error handling" do
      expect_any_instance_of(Timberline::Queue).to receive(:error_item).with(item)
      Timberline.error_item(item)
    end
  end

  describe ".pause" do
    context "when a Queue is not paused" do
      subject { Timberline.queue("pause_test_queue") }

      before do
        Timberline.pause(subject.queue_name)
      end

      it "pauses the queue" do
        expect(subject.paused?).to be true
      end
    end

    context "when a Queue is already paused" do
      subject { Timberline.queue("pause_test_queue") }

      before do
        subject.pause
        Timberline.pause(subject.queue_name)
      end

      it "keeps the queue paused" do
        expect(subject.paused?).to be true
      end
    end
  end

  describe ".unpause" do
    context "when a Queue is paused" do
      subject { Timberline.queue("pause_test_queue") }

      before do
        subject.pause
        Timberline.unpause(subject.queue_name)
      end

      it "unpauses the queue" do
        expect(subject.paused?).to be false
      end
    end

    context "when a Queue is already unpaused" do
      subject { Timberline.queue("pause_test_queue") }

      before do
        Timberline.unpause(subject.queue_name)
      end

      it "keeps the queue unpaused" do
        expect(subject.paused?).to be false
      end
    end
  end

  describe ".configure" do
    context "if Timberline hasn't been configured yet" do
      it "initializes a new configuration object" do
        Timberline.configure {}
        expect(Timberline.config).not_to be_nil  
      end

      it "yields the new config object to the block" do
        expect { |b| Timberline.configure &b }.to yield_with_args(Timberline.config)
      end
    end

    context "if Timberline has been configured" do
      before do
        Timberline.configure {}
      end

      it "yields the Timberlin config object to the block" do
        expect { |b| Timberline.configure &b }.to yield_with_args(Timberline.config)
      end
    end
  end

  describe ".max_retries" do
    context "if Timberline hasn't been configured yet" do
      before { Timberline.max_retries }

      it "initializes a new configuration object" do
        expect(Timberline.config).not_to be_nil  
      end
    end

    context "if Timberline has been configured" do
      before do
        Timberline.configure do |c|
          c.max_retries = 10
        end
      end

      it "returns the configured number of maximum retries" do
        expect(Timberline.max_retries).to eq(10)
      end
    end
  end

  describe ".stat_timeout" do
    context "if Timberline hasn't been configured yet" do
      before { Timberline.stat_timeout }

      it "initializes a new configuration object" do
        expect(Timberline.config).not_to be_nil
      end
    end

    context "if Timberline has been configured" do
      before do
        Timberline.configure do |c|
          c.stat_timeout = 10
        end
      end

      it "returns the configured number of minutes for stat timeout" do
        expect(Timberline.stat_timeout).to eq(10)
      end
    end
  end

  describe ".stat_timeout_seconds" do
    context "if Timberline hasn't been configured yet" do
      before { Timberline.stat_timeout_seconds }

      it "initializes a new configuration object" do
        expect(Timberline.config).not_to be_nil
      end
    end

    context "if Timberline has been configured" do
      before do
        Timberline.configure do |c|
          c.stat_timeout = 10
        end
      end

      it "returns the configured number of seconds for stat timeout" do
        expect(Timberline.stat_timeout_seconds).to eq(600)
      end
    end
  end
end
