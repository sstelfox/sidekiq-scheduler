$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sidekiq-scheduler/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sidekiq-scheduler"
  s.version     = SidekiqScheduler::VERSION
  s.authors     = ['Moove-IT', 'Adrian Gomez', "Morton Jonuschat"]
  s.email       = ["sidekiq-scheduler@moove-it.com"]
  s.homepage    = "https://github.com/SidekiqScheduler/sidekiq-scheduler"
  s.summary     = 'Light weight job scheduling extension for Sidekiq'
  s.description = "Light weight job scheduling extension for Sidekiq that adds support for executing recurring tasks."

  s.files = Dir["{app,bin,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency('sidekiq', '~> 2.0')
  s.add_dependency('redis', '~> 3.0')
  s.add_dependency('rufus-scheduler', '~> 2.0')
  s.add_dependency('multi_json', '~> 1.0')

  s.add_development_dependency 'rake'
  s.add_development_dependency 'timecop'

  s.add_development_dependency 'mocha'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mock_redis'
end