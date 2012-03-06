# delayed_job Sequel backend

## Installation

Add the gems to your Gemfile:

    gem 'delayed_job', '~> 3.0'
    gem 'delayed_job_sequel', '0.2.0'
  

That's it. Use [delayed_job as normal](http://github.com/collectiveidea/delayed_job).

Create the delayed_job tables with migration:

	Sequel.migration do
		up do
			create_table(:delayed_jobs, :ignore_index_errors=>true) do
				primary_key :id
				Integer :priority, :default=>0
				Integer :attempts, :default=>0
				String :handler, :text=>true
				DateTime :run_at
				DateTime :locked_at
				String :locked_by, :text=>true
				DateTime :failed_at
				String :last_error, :text=>true
				String :queue, :size=>128
			
				index [:locked_at], :name=>:index_delayed_jobs_locked_at
				index [:priority, :run_at], :name=>:index_delayed_jobs_run_at_priority
			end

		down do
			drop_table(:delayed_jobs)
		end
end
