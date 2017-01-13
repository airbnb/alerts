begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :test do
    ruby "test/check_query.rb"
  end

  task :default => [:test, :spec]


rescue LoadError
    # no rspec available
end
