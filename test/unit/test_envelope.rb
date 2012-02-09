require 'test_helper'
require 'date'

describe Timberline::Envelope do
  before do
    @envelope = Timberline::Envelope.new
  end

  describe "newly instantiated" do
    it "raises a MissingContentException when to_s is called because the contents are nil" do
      assert_raises Timberline::MissingContentException do
        @envelope.to_s
      end
    end

    it "has an empty hash for metadata" do
      assert_equal({}, @envelope.metadata)
    end

    it "allows for the reading of attributes via method_missing magic" do
      @envelope.metadata["original_queue"] = "test_queue"
      assert_equal "test_queue", @envelope.original_queue
    end

    it "allows for the setting of attributes via method_missing magic" do
      @envelope.original_queue = "test_queue"
      assert_equal "test_queue", @envelope.metadata["original_queue"]
    end
  end

  describe "with contents" do
    before do
      @envelope.contents = "Test data"
    end

    it "returns a JSON string when to_s is called" do
      json_string = @envelope.to_s
      json_data = JSON.parse(json_string)
      assert_equal "Test data", json_data["contents"]
    end

    it "only includes a 'contents' parameter by default" do
      json_string = @envelope.to_s
      json_data = JSON.parse(json_string)
      assert_equal 1, json_data.keys.size
    end

    it "also includes metadata, if provided" do
      time = DateTime.now
      time_s = DateTime.now.to_s
      @envelope.first_posted = time
      @envelope.origin_queue = "test_queue"

      json_string = @envelope.to_s
      json_data = JSON.parse(json_string)
      assert_equal "test_queue", json_data["origin_queue"]
      assert_equal time_s, json_data["first_posted"]
    end

    it "parses itself back correctly using from_json" do
      json_string = @envelope.to_s
      new_envelope = Timberline::Envelope.from_json(json_string)
      assert_equal @envelope.contents, new_envelope.contents
      assert_equal @envelope.metadata, new_envelope.metadata
    end
  end
end
