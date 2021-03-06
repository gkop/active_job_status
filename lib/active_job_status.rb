require "active_job_status/trackable_job"
require "active_job_status/job_tracker"
require "active_job_status/job_status"
require "active_job_status/job_batch"
require "active_job_status/version"
require "redis"

module ActiveJobStatus

  @@redis = Redis.new

  def self.redis= (redis)
    @@redis = redis
  end

  def self.redis
    @@redis
  end
end

