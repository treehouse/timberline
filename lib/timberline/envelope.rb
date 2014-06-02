class Timberline
  class Envelope

    def self.from_json(json_string)
      envelope = Envelope.new
      envelope.instance_variable_set("@metadata", JSON.parse(json_string))
      envelope.contents = envelope.metadata.delete("contents")
      envelope
    end

    attr_accessor :contents
    attr_reader   :metadata

    def initialize
      @metadata = {}
    end

    def to_s
      raise MissingContentException if contents.nil? || contents.empty?

      JSON.unparse(build_envelope_hash)
    end

    def method_missing(method_name, *args)
      method_name = method_name.to_s
      if method_name[-1] == "="
        assign_var(method_name[0, method_name.size - 1], args.first)
      else
        return metadata[method_name]
      end
    end

    private

    def build_envelope_hash
      { contents: contents }.merge(@metadata)
    end

    def assign_var(name, value)
      @metadata[name] = value
    end

  end

  class MissingContentException < Exception
  end
end
