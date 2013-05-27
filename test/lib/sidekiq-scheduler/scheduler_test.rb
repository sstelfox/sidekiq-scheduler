require 'test_helper'

require 'sidekiq-scheduler/schedule_store'

class ManagerTest < Minitest::Test
  describe 'SidekiqScheduler::Scheduler' do

    before do
      Sidekiq.dynamic_schedule = false
      Sidekiq.redis { |r| r.del(:schedules) }
      Sidekiq.redis { |r| r.del(:schedules_changed) }
      SidekiqScheduler::Scheduler.clear_schedule!
      SidekiqScheduler::Scheduler.send(:class_variable_set, :@@scheduled_jobs, {})
    end

    it 'enqueue constantizes' do
      # The job should be loaded, since a missing rails_env means ALL envs.
      ENV['RAILS_ENV'] = 'production'
      config = {
        'cron' => '* * * * *',
        'class' => 'SomeRealClass',
        'queue' => 'high',
        'args' => '/tmp'
      }

      Sidekiq::Client.expects(:push).with(
        {
          'cron' => '* * * * *',
          'class' => SomeRealClass,
          'queue' => 'high',
          'args' => ['/tmp']
        }
      )
      SidekiqScheduler::Scheduler.enqueue_from_config(config)
    end

    it 'enqueue_from_config respects queue params' do
      config = {
        'cron' => '* * * * *',
        'class' => 'SomeIvarJob',
        'queue' => 'high'
      }

      Sidekiq::Client.expects(:push).with(
        {
          'cron' => '* * * * *',
          'class' => SomeIvarJob,
          'args' => [],
          'queue' => 'high'
        }
      )

      SidekiqScheduler::Scheduler.enqueue_from_config(config)
    end

    it 'config makes it into the rufus_scheduler' do
      assert_equal(0, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      Sidekiq.schedule = {
        :some_ivar_job => {
          'cron' => '* * * * *',
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      }

      SidekiqScheduler::Scheduler.load_schedule!

      assert_equal(1, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      assert SidekiqScheduler::Scheduler.scheduled_jobs.include?(:some_ivar_job)
    end

    it 'can reload schedule' do
      Sidekiq.dynamic_schedule = true
      Sidekiq.schedule = {
        :some_ivar_job => {
          'cron' => '* * * * *',
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      }

      SidekiqScheduler::Scheduler.load_schedule!

      assert SidekiqScheduler::Scheduler.scheduled_jobs.include?('some_ivar_job')

      Sidekiq.redis { |r| r.del(:schedules) }
      Sidekiq.redis do |r|
        r.hset(
          :schedules,
          'some_ivar_job2',
          MultiJson.encode(
            {
              'cron' => '* * * * *',
              'class' => 'SomeIvarJob',
              'args' => '/tmp/2'
            }
          )
        )
      end

      SidekiqScheduler::Scheduler.reload_schedule!

      assert SidekiqScheduler::Scheduler.scheduled_jobs.include?('some_ivar_job')
      assert SidekiqScheduler::Scheduler.scheduled_jobs.include?('some_ivar_job2')

      assert_equal '/tmp/2', Sidekiq.schedule['some_ivar_job2']['args']
    end

    it 'load_schedule_job loads a schedule' do
      SidekiqScheduler::Scheduler.load_schedule_job(
        'some_ivar_job',
        {
          'cron' => '* * * * *',
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      )

      assert_equal(1, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      assert_equal(1, SidekiqScheduler::Scheduler.scheduled_jobs.size)
      assert SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?('some_ivar_job')
    end

    it 'load_schedule_job with every with options' do
      SidekiqScheduler::Scheduler.load_schedule_job(
        'some_ivar_job',
        {
          'every' => ['30s', {'first_in' => '60s'}],
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      )

      assert_equal(1, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      assert_equal(1, SidekiqScheduler::Scheduler.scheduled_jobs.size)
      assert SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?('some_ivar_job')
      assert SidekiqScheduler::Scheduler.scheduled_jobs['some_ivar_job'].params.keys.include?(:first_in)
    end

    it 'load_schedule_job with cron with options' do
      SidekiqScheduler::Scheduler.load_schedule_job(
        'some_ivar_job',
        {
          'cron' => ['* * * * *', {'allow_overlapping' => 'true'}],
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      )

      assert_equal(1, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      assert_equal(1, SidekiqScheduler::Scheduler.scheduled_jobs.size)
      assert SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?('some_ivar_job')
      assert SidekiqScheduler::Scheduler.scheduled_jobs['some_ivar_job'].params.keys.include?(:allow_overlapping)
    end

    it 'does not load the schedule without cron' do
      SidekiqScheduler::Scheduler.load_schedule_job(
        'some_ivar_job',
        {
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      )

      assert_equal(0, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      assert_equal(0, SidekiqScheduler::Scheduler.scheduled_jobs.size)
      assert !SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?('some_ivar_job')
    end

    it 'does not load the schedule with an empty cron' do
      SidekiqScheduler::Scheduler.load_schedule_job(
        'some_ivar_job',
        {
          'cron' => '',
          'class' => 'SomeIvarJob',
          'args' => '/tmp'
        }
      )

      assert_equal(0, SidekiqScheduler::Scheduler.rufus_scheduler.all_jobs.size)
      assert_equal(0, SidekiqScheduler::Scheduler.scheduled_jobs.size)
      assert !SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?('some_ivar_job')
    end

    it 'update_schedule' do
      Sidekiq.dynamic_schedule = true
      Sidekiq.schedule = {
        'some_ivar_job'     => {'cron' => '* * * * *', 'class' => 'SomeIvarJob', 'args' => '/tmp'},
        'another_ivar_job'  => {'cron' => '* * * * *', 'class' => 'SomeIvarJob', 'args' => '/tmp/5'},
        'stay_put_job'      => {'cron' => '* * * * *', 'class' => 'SomeJob', 'args' => '/tmp'}
      }

      SidekiqScheduler::Scheduler.load_schedule!

      SidekiqScheduler::Scheduler.scheduled_jobs['some_ivar_job'].expects(:unschedule)
      SidekiqScheduler::Scheduler.scheduled_jobs['another_ivar_job'].expects(:unschedule)

      SidekiqScheduler::ScheduleStore.set_schedule(
        'some_ivar_job',
        {
          'cron' => '* * * * *',
          'class' => 'SomeIvarJob',
          'args' => '/tmp/2'
        }
      )
      SidekiqScheduler::ScheduleStore.set_schedule(
        'new_ivar_job',
        {
          'cron' => '* * * * *',
          'class' => 'SomeJob',
          'args' => '/tmp/3'
        }
      )
      SidekiqScheduler::ScheduleStore.set_schedule(
        'stay_put_job',
        {
          'cron' => '* * * * *',
          'class' => 'SomeJob',
          'args' => '/tmp'
        }
      )
      SidekiqScheduler::ScheduleStore.remove_schedule('another_ivar_job')

      SidekiqScheduler::Scheduler.update_schedule

      %w(some_ivar_job new_ivar_job stay_put_job).each do |job_name|
        assert SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?(job_name)
        assert Sidekiq.schedule.keys.include?(job_name)
      end
      assert !SidekiqScheduler::Scheduler.scheduled_jobs.keys.include?('another_ivar_job')
      assert !Sidekiq.schedule.keys.include?('another_ivar_job')
      assert_equal 0, Sidekiq.redis { |r| r.scard(:schedules_changed) }
    end

  end
end