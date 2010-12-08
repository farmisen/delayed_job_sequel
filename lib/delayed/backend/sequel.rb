module Delayed
  module Backend
    module Sequel
      class Job

        def self.LazyJob
          @@LazyJob ||= self.createLazyJob()
        end

        def self.createLazyJob()
          eval <<-eos
                class LazyJob < ::Sequel::Model(:delayed_jobs)
                  include Delayed::Backend::Base
                  include Delayed::Backend::Sequel::LazyJob


                  class <<self
                    alias :create! :create
                  end

                  alias :save! :save
                  alias :update_attributes :update

                end

          eos
          Class.new(LazyJob)
        end

        class <<self
          def method_missing(sym, *args, &block)
            self.LazyJob.send sym, *args, &block
          end
        end

        def self.new(options)
          self.LazyJob.new(options)
        end
      end

      module LazyJob

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def find_available(worker_name, limit = 5, max_run_time = Worker.max_run_time)
            now = db_time_now
            scope = Job.where('(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', 
                       now, now - max_run_time, worker_name)
            scope = scope.where(:priority >= Worker.min_priority) if Worker.min_priority
            scope = scope.where(:priority <= Worker.max_priority) if Worker.max_priority
            scope = scope.order(:priority.desc, :run_at.asc).limit(limit)
            p scope.sql
            scope.all
          end

          # When a worker is exiting, make sure we don't have any locked jobs.
          def clear_locks!(worker_name)
            Job.filter("locked_by = '#{worker_name}'").update(:locked_at => nil, :locked_by => nil)
          end

          def db_time_now
            Time.now
          end

          def make_db_timestamp(time)
            "#{time.strftime('%Y-%m-%d %H:%M:%S')}.#{time.usec}#{time.strftime('%z')}"
          end

          def delete_all
            Job.delete()
          end

          def find(id)
            self[id]
          end
        end


        def ==(other_job)
          id == other_job.id
        end

        def before_create
          self.last_error ||= nil
          self.updated_at ||= Time.now
          self.locked_at  ||= nil
          self.locked_by  ||= nil
          self.failed_at  ||= nil
          self.attempts   ||= 0
          self.created_at ||= Time.now
          self.priority   ||= 0
        end

        def before_save
          set_default_run_at
          super
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(max_run_time, worker = worker_name)
          now = self.class.db_time_now
          affected_rows = if locked_by != worker
            # We don't own this job so we will update the locked_by name and the locked_at
            self.class.filter(:id => id).
                       filter('(locked_at IS NULL OR locked_at < ?) AND (run_at <= ?)', (now - max_run_time.to_i), now).
                       update(:locked_at => now, :locked_by => worker)
          else
            # We already own this job, this may happen if the job queue crashes.
            # Simply resume and update the locked_at
            self.class.filter(:id => id, :locked_by => worker).
                       update(:locked_at => now)
          end
          if affected_rows == 1
            self.locked_at    = now
            self.locked_by    = worker
            return true
          else
            return false
          end
        end


        private

        def make_db_timestamp(time)
          Job.make_db_timestamp(time)
        end

      end
    end
  end
end
