require 'sequel'
require 'delayed_job'
require 'delayed/serialization/sequel'
require 'delayed/backend/sequel'

Delayed::Worker.backend = :sequel
