module Delayed
  module Backend
    module Sequel
      class Job < ::Sequel::Model(:delayed_jobs)
        include Delayed::Backend::Base
        class <<self
#          alias :create! :create
        end
#        alias :save! :save
#        alias :update_attributes :update
        
        def self.before_fork 
        end
        def self.after_fork 
        end
        
        def before_save
          set_default_run_at
          super
        end
        
        def self.clear_locks!(worker_name)
          Job.filter("locked_by = '#{worker_name}'").update(:locked_at => nil, :locked_by => nil)
        end
        
        def self.find_available(worker_name, limit=5, max_run_time=Worker.max_run_time)
          ready_to_run = Job.filter('(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name)
          ready_to_run = ready_to_run.filter('priority >= ?', Worker.min_priority) if Worker.min_priority
          ready_to_run = ready_to_run.filter('priority <= ?', Worker.max_priority) if Worker.max_priority
          ready_to_run = ready_to_run.filter(:queue => Worker.queues) if Worker.queues.any?
          ready_to_run = ready_to_run.limit(limit)
          ready_to_run = ready_to_run.order(:priority).order_append(:run_at)
          ready_to_run.all
        end
        
        def lock_exclusively!(max_run_time, worker)
          now = self.class.db_time_now
          affected_rows = nil
          if locked_by != worker
            jobs = Job.filter('id = ? and (locked_at is null or locked_at < ?) and (run_at <= ?)', id, (now - max_run_time.to_i), now)
            affected_rows = jobs.update(:locked_at => now, :locked_by => worker)
          else
            jobs = Job.filter(:id => id, :locked_by => worker)
            affected_rows = jobs.update(:locked_at => now)
          end
          if affected_rows == 1
            self.reload
            return true
          else
            return false
          end
        end
        
        def self.db_time_now
          Time.now
        end
      end
      
    end
  end
end
