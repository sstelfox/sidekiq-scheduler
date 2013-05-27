require 'sidekiq-scheduler/launcher'

module SidekiqScheduler

  def self.enable_scheduler
    Sidekiq::Launcher.send(:include, SidekiqScheduler::Launcher)
  end

end