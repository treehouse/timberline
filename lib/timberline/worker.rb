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
        @executing_job = true
        item.started_processing_at = Time.now.to_f

        begin
          begin
            process_item(item)
          rescue StandardError => e
            handle_process_exception(e, item)
          end

          item.finished_processing_at = Time.now.to_f
          run_time = item.finished_processing_at - item.started_processing_at
          @queue.increment_run_time_by(run_time)
          @queue.increment_success_stat
        rescue ItemRetried, ItemErrored
          next
        ensure
          @executing_job = false
        end

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

    # Whether the worker is currently executing a job.
    #
    # @return [boolean]
    def executing_job?
      @executing_job == true
    end

    # Called when process_item has resulted in an exception. Exceptions are
    # handled by default by reraising. This method is available to allow
    # subclasses to override or extend how exceptions are handled. A subclass
    # may, for example, want to log errors, handle specific error types in
    # specific ways, or call error_item by default on all errors.
    #
    # @raise By default, raises the error it is provided.
    def handle_process_exception(exception, item)
      raise exception
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
