require 'rubygems'
require 'bundler/setup'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'logger'
require 'sequel'


@db = Sequel.sqlite

@db.create_table(:delayed_jobs) do
  primary_key :id
  Integer  :priority, :default => 0
  Integer  :attempts, :default => 0
  String   :handler, :text => true, :default => nil
  String   :last_error, :text => true, :default => nil
  DateTime :run_at, :default => nil
  DateTime :locked_at, :default => nil
  DateTime :failed_at, :default => nil
  String   :locked_by, :default => nil
  DateTime :created_at, :default => nil
  DateTime :updated_at, :default => nil
end

 @db.create_table(:story) do
    primary_key :id
    String :text
end

require 'benchmark'
require 'delayed_job'
require 'delayed_job_sequel'
require 'delayed/backend/shared_spec'

class Story < Sequel::Model(@db[:story])
  def tell; text; end
  def whatever(n, _); tell*n; end
  def self.count; end

  handle_asynchronously :whatever

  def update_attributes(param)
    update(param)
  end
end


