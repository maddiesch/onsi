require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :docs do
  desc 'Generate docs'
  task :generate do
    YARD::CLI::Yardoc.run
  end

  desc 'Get docs stats'
  task :stats do
    YARD::CLI::Stats.run('--list-undoc')
  end
end
