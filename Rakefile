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

  Rake::TestTask.new(:docs) do |t|
    t.ruby_opts << "-r./tests/fixtures.rb"
    t.test_files = FileList['tests/docs_test.rb']
    t.verbose = false
    #t.options = "-v"
  end

end

desc "Run RSpec with code coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task["test:all"].execute
end

desc "Reinstall gem"
task :reinstall do
  puts %x{rm -rf sinatra-rabbit-*.gem}
  puts %x{gem uninstall sinatra-rabbit --all -I -x}
  puts %x{gem build sinatra-rabbit.gemspec}
  puts %x{gem install sinatra-rabbit-*.gem --local}
end
