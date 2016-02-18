# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "timberline/version"

Gem::Specification.new do |s|
  s.name        = "timberline"
  s.version     = Timberline::VERSION
  s.authors     = ["Tommy Morgan"]
  s.email       = ["tommy.morgan@gmail.com"]
  s.homepage    = "http://github.com/treehouse/timberline"
  s.summary     = %q{Timberline is a simple and extensible queuing system built in Ruby and backed by Redis.}
  s.description = %q{Timberline is a simple and extensible queuing system built in Ruby and backed by Redis. It makes as few assumptions as possible about how you want to interact with your queues while also allowing for some functionality that should be universally useful, like allowing for automatic retries of jobs and queue statistics.}

  s.rubyforge_project = "timberline"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "redis"
  s.add_runtime_dependency "redis-namespace"
  s.add_runtime_dependency "trollop"
  s.add_runtime_dependency "daemons"

  s.add_development_dependency "yard"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", '~> 3.0.0.rc1'
  s.add_development_dependency "pry"
end
