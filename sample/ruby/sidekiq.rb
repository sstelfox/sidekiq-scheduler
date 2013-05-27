require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.options = YAML.load(File.open('config/sidekiq.yml'))

Sidekiq.configure_server do |config|
  config.redis = {:host => '..', :port =>'...'}
end

SidekiqScheduler.enable_scheduler

# Now run with:
#   bundle exec sidekiq-scheduler -r sample/sidekiq_server.rb