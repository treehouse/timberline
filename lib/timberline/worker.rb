class Timberline
  # Worker is the base class for Timberline Workers. It defines the basics for
  # processing items off of a queue; the idea is that creating your own worker
  # is as easy as extending Worker and implementing #process_item. You can also
  # override #keep_watching? and #initialize to provide your own custom behavior
  # easily, although this is not necessary.
  #
  class Worker
    # Run the watch loop for this worker. As long as #keep_watching?
    # returns true, this will pop items off the queue and process them
    # with #process_item. This method is also responsible for managing
    # some extra timberline metadata (tracking when processing starts and
    # stops, for example) and shouldn't typically be overridden when you
    # define your own worker.
    #
    # @param [String] queue_name the name of the queue to watch.
    #
    def watch(queue_name)
      @queue = Queue.new(queue_name)

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

    # Given an item off of the queue, process it appropriately.
    # Not implemented in Worker, as Worker is just a base class.
    #
    def process_item(item)
      raise NotImplementedError
    end

    # Determine whether or not the worker loop in #watch should continue
    # executing. By default this is always true.
    #
    # @return [boolean]
    def keep_watching?
      true
    end

    # Given an item this worker is processing, have the queue mark it
    # as fatally errored and raise an ItemErrored exception so that the
    # watch loop can process it correctly
    #
    # @raise [Timberline::ItemErrored]
    def error_item(item)
      @queue.error_item(item)
      raise Timberline::ItemErrored
    end

    # Given an item this worker is processing, have the queue mark it
    # attempt to retry it and raise an ItemRetried exception so that the
    # watch loop can process it correctly
    #
    # @raise [Timberline::ItemRetried]
    def retry_item(item)
      @queue.retry_item(item)
      raise Timberline::ItemRetried
    end
  end
end
