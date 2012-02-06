require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/unit/test_*.rb']
  t.verbose = true
  t.warning = true
end
