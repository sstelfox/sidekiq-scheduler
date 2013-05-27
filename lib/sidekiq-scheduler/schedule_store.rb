require 'multi_json'

module SidekiqScheduler
  module ScheduleStore


    # Retrieve the schedule configuration for the given name
    # if the name is nil it returns a hash with all the
    # names end their schedules.
    def self.get_schedule(name)
      encoded_schedule = Sidekiq.redis { |r| r.hget(:schedules, name) }
      encoded_schedule.nil? ? nil : MultiJson.decode(encoded_schedule)
    end

    # Gets the schedule as it exists in redis
    def self.get_all_schedules
      return unless Sidekiq.redis { |r| r.exists(:schedules) }

      schedules = {}
      Sidekiq.redis { |r| r.hgetall(:schedules) }.tap do |h|
        h.each do |name, config|
          schedules[name] = MultiJson.decode(config)
        end
      end

      schedules
    end

    # Create or update a schedule with the provided name and configuration.
    #
    # Note: values for class and custom_job_class need to be strings,
    # not constants.
    #
    #    Sidekiq.set_schedule('some_job', {:class => 'SomeJob',
    #                                     :every => '15mins',
    #                                     :queue => 'high',
    #                                     :args => '/tmp/poop'})
    def self.set_schedule(name, config)
      existing_config = get_schedule(name)
      unless existing_config && existing_config == config
        Sidekiq.redis { |r| r.hset(:schedules, name, MultiJson.encode(config)) }
        Sidekiq.redis { |r| r.sadd(:schedules_changed, name) }
      end

      config
    end

    # remove a given schedule by name
    def self.remove_schedule(name)
      Sidekiq.redis { |r| r.hdel(:schedules, name) }
      Sidekiq.redis { |r| r.sadd(:schedules_changed, name) }
    end

  end
end