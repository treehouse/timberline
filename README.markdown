# Timberline

![](https://travis-ci.org/treehouse/timberline.svg)&nbsp;
[![Gem Version](https://badge.fury.io/rb/timberline.svg)](http://badge.fury.io/rb/timberline)

## Purpose

Timberline is a dead-simple queuing service written in Ruby and backed by Redis.
It makes a few assumptions about how you'd like to handle your queues and what
kind of issues you might be dealing with:

1. Timberline assumes that you want to be able to programmatically retry some
   failed jobs, and that you want to keep track of jobs that totally errored out
   so that you can try them again.

2. Timberline assumes that you want to queue data, and not actions. You can have
   one app that puts data onto the queue and another app that reads data from
   the queue, and the only thing they have to have in common (aside from knowing
   what the data means) is that they both include Timberline.

3. Timberline assumes that it's preferable, if not important to you, to process
   jobs as fast as you possibly can. To that end, Timberline uses blocking reads
   in Redis to pull jobs off of the queue as soon as they're available.

## Documentation

Documentation for Timberline is available on rubydoc.info
[here](http://rubydoc.info/github/treehouse/timberline/frames). The code itself
is documented with YARD.

## Concepts

### The Envelope

Sounds SOAPy, I know. The envelope is a simple object that wraps the data you
want to put on the queue - it's responsible for tracking things like the job ID,
the queue it was put on, how many times it's been retried, etc., etc. It's also
accessible to both the queue processor and whatever is putting jobs on the
queue, so if you want to be able to check in on the administrative details (or
add some of your own) this is a great place to do it instead of muddying up the
meat of your message.

### Workers

Processing items on a Timberline queue is handled by Workers. A Worker can be
created as simply as providing a block that executes on job items, or you can
write your own Workers that perform special functionality.

### Retries

Sometimes jobs just fail because of something that was outside of your control.
Maybe there was a glitch and your HTTP connection to PayPal didn't go through,
or maybe Github is down right now, or... whatever. In these situations it makes
sense to re-queue jobs and let them retry - just don't let them do it forever or
they may never leave. Timberline is designed to make retrying jobs in these
circumstances super-easy.

### Errors

On the other hand, sometimes your jobs deserved to fail. Maybe there was a bug
in your processor code, or maybe a user was able to sneak bad data past you. In
any event, Timberline maintains an error queue where jobs go when they're
explicitly marked as bad jobs, or when they've been retried the maximum number
of times. You can then check the jobs out and resubmit them to their original
queue after you fix the issue.

## Usage

Timberline is designed to be as easy to work with as possible, and operates almost
like a DSL for interacting with stuff on the queue.

### Configuration

There are a few things that you probably want to be able to configure in
Timberline. At the moment this is largely stuff related to the redis server
connection, but you can also configure a namespace for your redis queues
(defaults to "timberline") and a maximum number of retry attempts for jobs in the
queue (more on that later). There are 3 ways to configure Timberline:

1. The most direct way is to configure Timberline via ruby code as follows:

        Timberline.configure do |c|
          c.database = 1
          c.host = "192.168.1.105"
          c.port = 12345
          c.password = "foobar"
        end

   ...As long as you run this block before you attempt to access your queues,
   your settings will all take effect. Redis defaults will be used if you omit
   anything.

2. If you prefer a static config file, you can write a YAML file like the following:

          database: 1
          host: 192.168.1.105
          port: 12345
          password: foobar

  ...and then use the `TIMBERLINE_YAML` constant to specify the file's location:

          TIMBERLINE_YAML = 'path/to/your/yaml/file.yaml'

3. Running on Heroku? Define an environment variable for the URL:

        export TIMBERLINE_URL="redis://:foobar@192.168.1.105:12345/1?timeout=99&namespace=my_namespace"

### Pushing jobs onto a queue

To push a job onto the queue you'll want to make use of the `Timberline.push`
method, like so:

    Timberline.push "queue_name", data, { other_data: some_stuff }

`queue_name` is the name of the queue you want to push data onto; `data` is the
data you want to push onto the queue (remember that this all gets converted to
JSON, so you probably want to stick to things that represent well as strings),
and the optional third argument is a hash of any extra parameters you want to
include in the job's envelope.

### Pushing jobs onto a queue for execution at a latter day/month/century

To push a job onto the queue to be run at a latter time, provide a `run_at`
attribute as part of third argument to `Timberline.push`. For example, if you
wanted to run a job 5 minutes from now, you might do something like this:

    Timeberline.push "queue_name", data, { run_at: DateTime.now + 300 }

*Caveat*: There are no guarantees the job will run exactly at the time provided,
just that it will be executed by the watcher some time after the provided `run_at`
time.

### Reading from a queue

Reading from a queue is pretty simple in Timberline. You can simply write
something like the following:

    Timberline.watch "queue_name" do |job|
      begin
        puts job.other_data
        doSomethingWithThisStuff(job.contents)
      rescue SomeTransientError
        retry_job(job)
      rescue SomeFatalError
        error_job(job)
      end
    end

You will, in all likelihood, be writing more complicated stuff than this, of
course. But you call Timberline.watch and provide it with a queue name and a block
that will be called for each job as Timberline reads them off of the queue. Things
to note:

- The variable that will be passed into the block is the envelope for the job.
  To read what you actually posted into the queue, use job.contents.
- The envelope makes use of method\_missing to give you easy access to your
  metadata (note that we used job.other\_data to access the other\_data property
  that we added in the pushing example).
- retry\_job and error\_job are exactly what they seem like - they either try to
  retry the job in the event of a transient error, or put it on the error queue
  for processing if a more fatal error occurs.

### Error queues

Each queue has its own error queue, accessible through `Queue#error_queue`.
You can pop items directly off of the queue to operate on them if you want, or
you could write a queue processor that reads off of that queue.

### Using the binary

In order to make reading off of the queue easier, there's a binary named
`timberline` included with this gem.

Example:

    # timberline_sample.rb
    TIMBERLINE_YAML = "timberline_sample.yaml"

    watch "sample_queue" do |job|
      puts job.contents
    end

The above file, when executed via `timberline timberline_sample.rb`, will print out
the value of any object put on the queue. If no objects are on the queue it will
block until either the process is killed, or until something is added to the
queue.

There are some options to the Timberline binary that you may find helpful -
`timberline --help` for more.

### Rails

If you're using Timberline in conjunction with a Rails environment, check out
the [timberline-rails](https://github.com/treehouse/timberline-rails) gem.

### Redis Failover

The Redis client (>= v3.2) is able to [perform automatic Redis
connection](https://github.com/redis/redis-rb#sentinel-support) failovers by
using [Redis Sentinel](http://redis.io/topics/sentinel). In cases where this is
enabled, pass sentinel configuration on to the Redis client using the
"sentinels" key a configuration:

Via timberline.yml:

```yaml
host: 127.0.0.1
sentinels:
  - host: 127.0.0.1
    port: 26379
```

Via the Timberline.configure:

```ruby
Timberline.configure do |c|
  # ...
  c.sentinels = [{ host: 127.0.0.1, port: 26379 }]
end
```

Via the ENV VAR
```bash
export TIMBERLINE_URL="redis://:foobar@192.168.1.105:12345/1?sentinel=host1:1111&sentinel=host2:2222"
```

## TODO

Still to be done:

- **Monitor** - A simple Sinatra interface for monitoring the statuses of queues and
  observing/resubmitting errored-out jobs.
- **Forking** - Timberline should support forking in its watcher model so that jobs can
  be run in parallel and independently of each other.

## Future

Stuff that would be cool but isn't quite on the radar yet:

- Client libraries for other languages - maybe you want to put stuff onto the
  queue using Ruby but read from it in, say, Java. Or vice-versa. Or whatever.
  The queue data should be platform-agnostic.

## Contributions

If Timberline interests you and you think you might want to contribute, hit me up
over Github. You can also just fork it and make some changes, but there's a
better chance that your work won't be duplicated or rendered obsolete if you
check in on the current development status first.

## Development notes

You need Redis installed to do development on Timberline, and currently the test
suites assume that you're using the default configurations for Redis. That
should probably change, but it probably won't until someone needs it to.

Gem requirements/etc. should be handled by Bundler.

## License
Copyright (C) 2014 by Tommy Morgan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
