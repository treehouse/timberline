class Timberline
  class AnonymousWorker < Worker
    def initialize(queue_name, &block)
      super(queue_name)
      @block = block
      fix_block_binding
    end

    def process_item(item)
      @block.call(item, self)
    end

    def fix_block_binding
      binding = @block.binding
      binding.eval <<-HERE
        def retry_item(item)
          Timberline.retry_item(item)
          raise Timberline::ItemRetried
        end

        def error_item(item)
          Timberline.error_item(item)
          raise Timberline::ItemErrored
        end
      HERE
    end
  end
end
