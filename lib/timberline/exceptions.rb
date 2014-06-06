class Timberline

  # Used to indicate that an Envelope does not yet have contents, but is being
  # operated on as though it should.
  #
  class MissingContentException < Exception; end

  # Raised to indicate that the item currently being processed was retried.
  # Prevents Workers from treating the item as a success.
  #
  class ItemRetried < Exception; end

  # Raised to indicate that the item currently being processed experienced a
  # fatal error. Prevents Workers from treating the item as a success.
  #
  class ItemErrored < Exception; end
end
