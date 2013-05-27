require 'sidekiq-scheduler/schedule_store'

module SidekiqScheduler
  module Schedule

    # Accepts a new schedule configuration of the form:
    #
    #   {
    #     "MakeTea" => {
    #       "every" => "1m" },
    #     "some_name" => {
    #       "cron"        => "5/* * * *",
    #       "class"       => "DoSomeWork",
    #       "args"        => "work on this string",
    #       "description" => "this thing works it"s butter off" },
    #     ...
    #   }
    #
    # Hash keys can be anything and are used to describe and reference
    # the scheduled job. If the "class" argument is missing, the key
    # is used implicitly as "class" argument - in the "MakeTea" example,
    # "MakeTea" is used both as job name and sidekiq worker class.
    #
    # :cron can be any cron scheduling string
    #
    # :every can be used in lieu of :cron. see rufus-scheduler's 'every' usage
    # for valid syntax. If :cron is present it will take precedence over :every.
    #
    # :class must be a sidekiq worker class. If it is missing, the job name (hash key)
    # will be used as :class.
    #
    # :args can be any yaml which will be converted to a ruby literal and
    # passed in a params. (optional)
    #
    # :rails_env is in the list of Envs where the job gets loaded. Envs are
    # comma separated (optional)
    #
    # :description is just that, a description of the job (optional). If
    # params is an array, each element in the array is passed as a separate
    # param, otherwise params is passed in as the only parameter to perform.
    def schedule=(schedule_hash)
      schedule_hash = prepare_schedule(schedule_hash)

      if dynamic_schedule
        schedule_hash.each do |name, job_spec|
          SidekiqScheduler::ScheduleStore.set_schedule(name, job_spec)
        end
      end
      @schedule = schedule_hash
    end

    def schedule
      @schedule ||= {}
    end

    def dynamic_schedule=(dynamic_schedule)
      @dynamic_schedule = dynamic_schedule
    end

    def dynamic_schedule
      @dynamic_schedule ||= false
    end

    # reloads the schedule from redis
    def reload_schedule!
      @schedule = SidekiqScheduler::ScheduleStore.get_all_schedules
    end

    private

    def prepare_schedule(schedule_hash)
      prepared_hash = {}
      schedule_hash.each do |name, job_spec|
        job_spec = job_spec.dup
        job_spec['class'] = name unless job_spec.key?('class') || job_spec.key?(:class)
        prepared_hash[name] = job_spec
      end
      prepared_hash
    end

  end
end

Sidekiq.extend SidekiqScheduler::Schedule