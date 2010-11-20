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
            right_now = db_time_now
            filters   = []
            filters << "(run_at <= '#{make_db_timestamp(right_now)}' AND (locked_at IS NULL OR locked_at < '#{make_db_timestamp(right_now - max_run_time)}') OR locked_by = '#{worker_name}') AND failed_at IS NULL"
            filters << "priority >= #{Worker.min_priority.to_i}" if Worker.min_priority
            filters << "priority <= #{Worker.max_priority.to_i}" if Worker.max_priority
            Job.filter(filters.join(' and ')).order(:priority, :run_at).limit(limit).all()
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
          right_now     = self.class.db_time_now
          overtime      = right_now - max_run_time.to_i

          affected_rows = if locked_by != worker
                            filter = "id = #{id} and (locked_at is null or locked_at < '#{make_db_timestamp(overtime)}') and (run_at <= '#{make_db_timestamp(right_now)}')"
                            Job.filter(filter).update(:locked_at => right_now, :locked_by => worker)
                          else
                            filter = "id = #{id} and locked_by = '#{worker}'"
                            Job.filter(filter).update(:locked_at => right_now)
                          end

          if affected_rows == 1
            self.locked_at = right_now
            self.locked_by = worker
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
