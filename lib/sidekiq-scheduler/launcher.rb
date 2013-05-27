require 'sidekiq/launcher'

require 'sidekiq-scheduler/manager'

module SidekiqScheduler::Launcher

    def self.included(base)
      base.class_eval do
        alias_method :run_launcher, :run
        alias_method :run, :run_scheduler

        alias_method :stop_launcher, :stop
        alias_method :stop, :stop_scheduler
      end
    end

    def run_scheduler
      @scheduler = SidekiqScheduler::Manager.new(options)
      @scheduler.start
      run_launcher
    end

    def stop_scheduler
      @scheduler.stop
      stop_launcher
    end

end