require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

begin
  require "rdoc/task"
  RDoc::Task.new do |rdoc|
    rdoc.main = "README.md"
    rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
  end
rescue LoadError
end