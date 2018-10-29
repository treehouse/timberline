require 'spec_helper'

describe Timberline::Envelope do
  describe "newly created" do
    it "has no contents" do
      expect(subject.contents).to be_nil
    end

    it "has a metadata object" do
      expect(subject.metadata).not_to be_nil
    end

    it "has an empty hash for metadata" do
      expect(subject.metadata).to eq({})
    end
  end

  describe "#to_s" do
    context "When the envelope has no contents" do
      before do
        subject.contents = nil
      end

      it "raises a MissingContentException" do
        expect { subject.to_s }.to raise_error(Timberline::MissingContentException)
      end
    end

    context "When the envelope has contents" do
      before do
        subject.contents = "Wheeee!"
      end

      it "renders a JSON string of the envelope's data" do
        expect(subject.to_s).to eq(JSON.unparse({contents: "Wheeee!"}))
      end
    end

    context "When the envelope has contents and metadata" do
      before do
        subject.contents = "Wheeee!"
        subject.fritters = "the bacon kind"
      end

      it "renders a JSON string of the envelope's data" do
        expect(subject.to_s).to eq(JSON.unparse({contents: "Wheeee!", fritters: "the bacon kind"}))
      end
    end
  end

  describe "#method_missing" do
    context "When the missing method has an = at the end" do
      before do
        subject.fritters = "the bacon kind"
      end

      it "acts like a setter for the metadata object" do
        expect(subject.metadata["fritters"]).to eq("the bacon kind")
      end
    end

    context "When the missing method doesn't have an = at the end" do
      before do
        subject.metadata["fritters"] = "the bacon kind"
      end

      it "acts like a getter for the metadata object" do
        expect(subject.fritters).to eq("the bacon kind")
      end
    end
  end

  describe ".from_json" do
    let(:data_hash) { { contents: "hey guys!", test: true, fritters: "the bacon kind" } }
    let(:json_string) { JSON.unparse(data_hash) }
    let(:envelope) { Timberline::Envelope.from_json(json_string) }

    it "creates a Timberline::Envelope" do
      expect(envelope).to be_a Timberline::Envelope
    end

    it "correctly parses the contents" do
      expect(envelope.contents).to eq(data_hash[:contents])
    end

    it "correctly parses the metadata" do
      expect(envelope.test).to be true
      expect(envelope.fritters).to eq "the bacon kind"
    end
  end

  describe "#operate_later?" do
    let(:base_data_hash) { { contents: "test content" } }
    let(:json_string) { JSON.unparse(data_hash) }
    let(:envelope) { Timberline::Envelope.from_json(json_string) }

    context "job without run_at set" do
      let(:data_hash) { base_data_hash }

      it "can operate on the envelope now" do
        expect(envelope.open_later?).to eq(false)
      end
    end

    context "future job with run_at set" do
      let(:data_hash) do
        # 5min from now
        base_data_hash.merge(run_at: DateTime.now + 300)
      end

      it "can operate on the envelope later" do
        expect(envelope.open_later?).to eq(true)
      end
    end

    context "old job with run_at set" do
      let(:data_hash) do
        # 1s ago
        base_data_hash.merge(run_at: DateTime.now - 1)
      end

      it "can operate on the envelope now" do
        expect(envelope.open_later?).to eq(false)
      end
    end
  end
end
