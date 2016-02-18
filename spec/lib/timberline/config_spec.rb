require 'spec_helper'

describe Timberline::Config do
  describe "newly created" do
    context "when the TIMBERLINE_URL env var is defined" do
      before do
        ENV["TIMBERLINE_URL"] = "redis://:apassword@ahostname:9000/3?timeout=666&namespace=foobar&sentinel=sentinel1:1&sentinel=sentinel2:2&max_retries=99"
      end

      after do
        ENV.delete("TIMBERLINE_URL")
      end

      it "loads the host variable from the env var" do
        expect(subject.host).to eq("ahostname")
      end

      it "loads the port variable from the env var" do
        expect(subject.port).to eq(9000)
      end

      it "loads the timeout variable from the env var" do
        expect(subject.timeout).to eq(666)
      end

      it "loads the password from the env var" do
        expect(subject.password).to eq("apassword")
      end

      it "loads the database from the env var" do
        expect(subject.database).to eq(3)
      end

      it "loads the namespace from the env var" do
        expect(subject.namespace).to eq("foobar")
      end

      it "loads the max_retries from the env var" do
        expect(subject.max_retries).to eq(99)
      end

      it "loads the sentinel servers" do
        expect(subject.sentinels).to eq([
          { "host" => "sentinel1", "port" => 1 },
          { "host" => "sentinel2", "port" => 2 }
        ])
      end
    end

    context "when the TIMBERLINE_YAML constant is defined" do
      context "and the specified file exists" do
        before do
          SpecSupport::TimberlineYaml.load_constant
        end

        after do
          SpecSupport::TimberlineYaml.destroy_constant
        end

        it "loads the host variable from the config file" do
          expect(subject.host).to eq("localhost")
        end

        it "loads the port variable from the config file" do
          expect(subject.port).to eq(12345)
        end

        it "loads the timeout variable from the config file" do
          expect(subject.timeout).to eq(10)
        end

        it "loads the password from the config file" do
          expect(subject.password).to eq("foo")
        end

        it "loads the max_retries from the config file" do
          expect(subject.max_retries).to eq(1212)
        end

        it "loads the database from the config file" do
          expect(subject.database).to eq(3)
        end

        it "loads the namespace from the config file" do
          expect(subject.namespace).to eq("treecurve")
        end

        it "loads the sentinels from the config file" do
          sentinels = [{"host" => "localhost", "port" => 111111}]
          expect(subject.sentinels).to eq sentinels
        end
      end

      context "and the specified file doesn't exist" do
        before do
          SpecSupport::TimberlineYaml.load_constant_for_missing_file
        end

        after do
          SpecSupport::TimberlineYaml.destroy_constant
        end

        it "raises an exception to let you know the file doesn't exist" do
          expect { Timberline::Config.new }.to raise_error
        end
      end
    end

    context "when no configuration exists" do
      it "configures a default namespace of 'timberline'" do
        expect(subject.namespace).to eq("timberline")
      end

      it "configures a default max_retries of 5" do
        expect(subject.max_retries).to eq(5)
      end

      it "doesn't configure any redis settings so that redis will use its own defaults" do
        [:database, :host, :port, :timeout, :password, :logger].each do |value|
          expect(subject.send(value)).to be_nil
        end
      end
    end
  end

  describe "#redis_config" do
    subject { Timberline::Config.new }

    it "returns a hash" do
      expect(subject.redis_config).to be_a Hash
    end

    context "when only defaults have been configured" do
      it "is empty" do
        expect(subject.redis_config).to be_empty
      end
    end

    context "when it has been fully configured" do
      before do
        subject.database = 1
        subject.host     = "localhost"
        subject.port     = 1234
        subject.timeout  = 15
        subject.password = "fritters"
        subject.logger   = Logger.new(STDOUT)
      end

      it "includes the appropriate redis configuration keys" do
        [:db, :host, :port, :timeout, :password, :logger].each do |key|
          expect(subject.redis_config).to have_key key
        end
      end
    end
  end
end
