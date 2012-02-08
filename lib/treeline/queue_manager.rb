class Treeline
  class QueueManager
    attr_reader :queue_list

    def initialize
      @queue_list = {}
    end

    def error_queue
      @error_queue ||= Queue.new("treeline_errors")
    end

    def queue(queue_name)
      if @queue_list[queue_name].nil?
        @queue_list[queue_name] = Queue.new(queue_name)
      end
      @queue_list[queue_name]
    end

    def push(queue_name, data, metadata={})
      data = wrap(data, metadata.merge({:origin_queue => queue_name}))
      queue(queue_name).push(data)
    end

    def retry_job(job)
      if (job.retries < Treeline.max_retries)
        job.retries += 1
        job.last_tried_at = DateTime.now
        queue(job.origin_queue).push(job)
      else
        error_job(job)
      end
    end

    def error_job(job)
      job.fatal_error_at = DateTime.now
      error_queue.push(job)
    end

    def watch(queue_name, &block)
      queue = queue(queue_name)
      while(true)
        job = queue.pop
        fix_binding(block)
        block.call(job, self)
      end
    end

    private
    def wrap(contents, metadata)
      env = Envelope.new
      env.contents = contents
      metadata.each do |key, value|
        env.send("#{key.to_s}=", value)
      end

      env.retries = 0
      env.submitted_at = DateTime.now

      env
    end

    # Hacky-hacky. I like the idea of calling retry_job(job) and error_job(job)
    # directly from the watch block, but this seems ugly. There may be a better
    # way to do this.
    def fix_binding(block)
      binding = block.binding
      binding.eval <<-HERE
        def retry_job(job)
          Treeline.retry_job(job)
        end

        def error_job(job)
          Treeline.error_job(job)
        end
      HERE
    end
  end
end
