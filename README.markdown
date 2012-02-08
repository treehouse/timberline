# Treeline

## Purpose

Treeline is a dead-simple queuing service written in Ruby and backed by Redis.
It makes a few assumptions about how you'd like to handle your queues and what
kind of issues you might be dealing with:

1. Treeline assumes that you want to be able to programmatically retry some
   failed jobs, and that you want to keep track of jobs that totally errored out
   so that you can try them again.

2. Treeline assumes that you want to queue data, and not actions. You can have
   one app that puts data onto the queue and another app that reads data from
   the queue, and the only thing they have to have in common (aside from knowing
   what the data means) is that they both include Treeline.

3. Treeline assumes that it's preferable, if not important to you, to process
   jobs as fast as you possibly can. To that end, Treeline uses blocking reads
   in Redis to pull jobs off of the queue as soon as they're available.

## Concepts

### Retries

Sometimes jobs just fail because of something that was outside of your control.
Maybe there was a glitch and your HTTP connection to PayPal didn't go through,
or maybe Github is down right now, or... whatever. In these situations it makes
sense to re-queue jobs and let them retry - just don't let them do it forever or
they may never leave. Treeline is designed to make retrying jobs in these
circumstances super-easy.

### Errors

On the other hand, sometimes your jobs deserved to fail. Maybe there was a bug
in your processor code, or maybe a user was able to sneak bad data past you. In
any event, Treeline maintains an error queue where jobs go when they're
explicitly marked as bad jobs, or when they've been retried the maximum number
of times. You can then check the jobs out and resubmit them to their original
queue after you fix the issue.

### The Envelope

Sounds SOAPy, I know. The envelope is a simple object that wraps the data you
want to put on the queue - it's responsible for tracking things like the job ID,
the queue it was put on, how many times it's been retried, etc., etc. It's also
accessible to both the queue processor and whatever is putting jobs on the
queue, so if you want to be able to check in on the administrative details (or
add some of your own) this is a great place to do it instead of muddying up the
meat of your message.

## Usage

Treeline is designed to be as easy to work with as possible, and operates almost
like a DSL for interacting with stuff on the queue.

### Configuration

There are a few things that you probably want to be able to configure in
Treeline. At the moment this is largely stuff related to the redis server
connection, but you can also configure a namespace for your redis queues
(defaults to "treeline") and a maximum number of retry attempts for jobs in the
queue (more on that later). There are 3 ways to configure Treeline:

1. The most direct way is to configure Treeline via ruby code as follows:

        Treeline.config do |c|
          c.database = 1
          c.host = "192.168.1.105"
          c.port = 12345
          c.password = "foobar"
        end
   
   ...As long as you run this block before you attempt to access your queues,
   your settings will all take effect. Redis defaults will be used if you omit
   anything.

2. If you're including treeline in a Rails app, there's a convenient way to
   configure it that should fit in with the rest of your app - if you include a
   yaml file named treeline.yaml in your config directory, Treeline will
   automatically detect it and load it up. The syntax for this file is
   shockingly boring:

        database: 1
        host: 192.168.1.105
        port: 12345
        password: foobar

3. Like the yaml format but you're not using Rails? Don't worry, just write your
   yaml file and set the TREELINE\_YAML constant inside your app like so:

        TREELINE_YAML = 'path/to/your/yaml/file.yaml'

### Pushing jobs onto a queue

To push a job onto the queue you'll want to make use of the `Treeline#push`
method, like so:

         Treeline.push "queue_name", data, { :other_data => some_stuff }

`queue_name` is the name of the queue you want to push data onto; data is the
data you want to push onto the queue (remember that this all gets converted to
JSON, so you probably want to stick to things that represent well as strings),
and the optional third argument is a hash of any extra parameters you want to
include in the job's envelope.

### Reading from a queue

Reading from a queue is pretty simple in Treeline. You can simply write
something like the following:

    Treeline.watch "queue_name" do |job|
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
course. But you call Treeline.watch and provide it with a queue name and a block
that will be called for each job as Treeline reads them off of the queue. Things
to note:

- The variable that will be passed into the block is the envelope for the job.
  To read what you actually posted into the queue, use job.contents.
- The envelope makes use of method\_missing to give you easy access to your
  metadata (note that we used job.other\_data to access the other\_data property
  that we added in the pushing example).
- retry\_job and error\_job are exactly what they seem like - they either try to
  retry the job in the event of a transient error, or put it on the error queue
  for processing if a more fatal error occurs.

### The error queue

If you want to interact with the error queue directly, it's accessible via
`Treeline#error_queue`. You can pop items directly off of the queue to operate
on them if you want, or you could write a queue processor that reads off of that
queue (its queue name should always be "treeline\_errors").

### Using the binary

In order to make reading off of the queue easier, there's a binary named
`treeline` included with this gem. The binary is currently very simple, as it
loads in a named file and executes the code in it in the context of the Treeline
class.

Example:

    # treeline_sample.rb
    TREELINE_YAML = "treeline_sample.yaml"

    watch "sample_queue" do |job|
      puts job.contents
    end

The above file, when executed via `treeline treeline_sample.rb`, will print out
the value of any object put on the queue. If no objects are on the queue it will
block until either the process is killed, or until something is added to the
queue.

## TODO

Still to be done:

- A simple Sinatra interface for monitoring the statuses of queues and
  observing/resubmitting errored-out jobs.
- Binary updates - the binary should be daemonizable, and should also probably
  fork processes for each job that it processes so that it's more robust.
- DSL improvements - the DSL-ish setup for Treeline could probably use some
  updates to be both more obvious and easier to use.
- Documentation - need to get YARD docs added so that the API is more completely
  documented. For the time being, though, there are some fairly comprehensive
  test suites.
- Timing - it would be crazy useful to be able to automatically log per-queue
  statistics about how long jobs are taking. Definitely something like an "over
  the last 5 minutes/past 1000 jobs" stat would be useful, but we may also be
  interested in some kind of lifetime average.

## Future

Stuff that would be cool but isn't quite on the radar yet:

- Client libraries for other languages - maybe you want to put stuff onto the
  queue using Ruby but read from it in, say, Java. Or vice-versa. Or whatever.
  The queue data should be platform-agnostic.

## Contributions

If Treeline interests you and you think you might want to contribute, hit me up
over Github. You can also just fork it and make some changes, but there's a
better chance that your work won't be duplicated or rendered obsolete if you
check in on the current development status first.

## Development notes

You need Redis installed to do development on Treeline, and currently the test
suites assume that you're using the default configurations for Redis. That
should probably change, but it probably won't until someone needs it to.

Gem requirements/etc. should be handled by Bundler.

## License
Copyright (C) 2012 by Tommy Morgan

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
