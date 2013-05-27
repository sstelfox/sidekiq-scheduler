require 'celluloid'
require 'redis'
require 'multi_json'

require 'sidekiq/util'

require 'sidekiq-scheduler/scheduler'
require 'sidekiq-scheduler/schedule'

module SidekiqScheduler

  # The delayed job router in the system.  This
  # manages the scheduled jobs pushed messages
  # from Redis onto the work queues
  #
  class Manager

    def initialize(options={})
      @enabled = options[:scheduler]

      Sidekiq.dynamic_schedule = options[:dynamic] || false
      Sidekiq.schedule = options[:schedule] if options[:schedule]
    end

    def stop
      SidekiqScheduler::Scheduler.stop
    end

    def start
      SidekiqScheduler::Scheduler.start
    end

  end

end