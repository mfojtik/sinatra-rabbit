require 'rake/testtask'

namespace :test do

  Rake::TestTask.new(:all) do |t|
    t.ruby_opts << "-r./tests/fixtures.rb"
    t.test_files = FileList['tests/*_test.rb']
    t.verbose = false
    t.options = "-v"
  end

  Rake::TestTask.new(:app) do |t|
    t.ruby_opts << "-r./tests/fixtures.rb"
    t.test_files = FileList['tests/app_test.rb']
    t.verbose = false
    t.options = "-v"
  end

  Rake::TestTask.new(:dsl) do |t|
    t.ruby_opts << "-r./tests/fixtures.rb"
    t.test_files = FileList['tests/dsl_test.rb']
    t.verbose = false
    #t.options = "-v"
  end

end

desc "Run RSpec with code coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task["test:all"].execute
end
