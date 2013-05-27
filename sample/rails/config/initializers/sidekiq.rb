Sidekiq.configure_server do |config|
  config.redis = {:host => '..', :port =>'...'}
end

SidekiqScheduler.enable_scheduler