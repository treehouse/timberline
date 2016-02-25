class Timberline
  # An Envelope in Timberline is what gets passed along on the queue.
  # The message itself - the part that the workers should intend to operate on - 
  # is stored in the `contents` field of the Envelope. Any other data on the
  # envelope is considered metadata. Metadata is mostly used by Timberline itself,
  # but is also exposed to the end user in case they have any need for it.
  #
  # @attr [#to_json] contents the contents of the envelope; the message to be 
  #   passed on the queue
  # @attr [Hash] metadata the metadata information associated with the envelope
  #
  class Envelope

    # Given a JSON string representing an envelope, build an Envelope object
    # with the appropriate data.
    #
    # @param [String] json_string the JSON string to parse
    # @return [Envelope]
    #
    def self.from_json(json_string)
      envelope = Envelope.new
      envelope.instance_variable_set("@metadata", JSON.parse(json_string))
      envelope.contents = envelope.metadata.delete("contents")
      envelope
    end

    attr_accessor :contents
    attr_reader   :metadata

    # Instantiates an Envelope with no metadata and nil contents.
    # @return [Envelope]
    #
    def initialize
      @metadata = {}
    end

    # Builds a JSON string version of the envelope.
    #
    # @raise [MissingContentException] if the envelope is empty (has no contents)
    # @return [String] a JSON representation of the envelope
    #
    def to_s
      raise MissingContentException if contents.nil? || contents.empty?

      JSON.unparse(build_envelope_hash)
    end

    # Determines if an envelope should be operated later than
    # right now.
    #
    # @return [Boolean]
    def open_later?
      return false unless run_at

      open_time = DateTime.parse(run_at)
      DateTime.now < open_time
    end

    # Passes any missing methods on to the metadata hash to provide better access.
    # @example Easily read from metadata
    #   some_envelope.origin_queue # returns metadata["origin_queue"]
    # @example Easily write to metadata
    #   some_envelope.origin_queue = "test_queue" # sets metadata["origin_queue"] to "test_queue"
    #
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
end
