class Timberline
  class Worker
    def initialize(queue_name)
      @queue = Queue.new(queue_name)
    end

    def watch
      while(keep_watching?)
        item = @queue.pop
        item.started_processing_at = Time.now.to_f

        begin
          process_item(item)
        rescue ItemRetried, ItemErrored
          next
        end

        item.finished_processing_at = Time.now.to_f
        @queue.add_success_stat(item)
      end
    end

    def process_item(item)
      raise NotImplementedError
    end

    def keep_watching?
      true
    end
  end
end
