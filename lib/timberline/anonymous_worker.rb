class Timberline
  # The AnonymousWorker is exactly what it says on the tin - a way to process a queue
  # without defining a new class, by instead just passing in a block that will be
  # executed for each item on the queue as it's popped.
  #
  class AnonymousWorker < Worker

    # Creates a new AnonymousWorker.
    # The block's binding will be updated to give it access to retry_item
    # and error_item so that the block can easily control the processing
    # flow for queued items.
    #
    # @param [Block] block the block to run against each item that gets popped 
    #   off the queue.
    #
    # @example Creating a simple AnonymousWorker
    #   AnonymousWorker.new { |item| puts item.contents }
    #
    # @return [AnonymousWorker]
    #
    def initialize(&block)
      @block = block
      fix_block_binding
    end

    # @see Timberline::Worker#watch
    #
    def process_item(item)
      @block.call(item, self)
    end

  private
    def fix_block_binding
      binding = @block.binding
      binding.eval <<-HERE
        def retry_item(item)
          Worker.retry_item(item)
        end

        def error_item(item)
          Worker.error_item(item)
        end
      HERE
    end
  end
end
