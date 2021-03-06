require "spec_helper"

describe ActiveJobStatus::JobBatch do

  let!(:batch_id) { Time.now }

  let!(:redis) { ActiveJobStatus.redis }

  let!(:job1) { TrackableJob.perform_later }
  let!(:job2) { TrackableJob.perform_later }
  let!(:job3) { TrackableJob.perform_later }
  let!(:job4) { TrackableJob.perform_later }

  let!(:first_jobs) { [job1.job_id, job2.job_id] }
  let!(:addl_jobs) { [job3.job_id, job4.job_id] }
  let!(:total_jobs) { first_jobs + addl_jobs }

  let!(:batch) { ActiveJobStatus::JobBatch.new(batch_id: batch_id,
                                              job_ids: first_jobs) }

  describe "#initialize" do
    it "should create an object" do
      expect(batch).to be_an_instance_of ActiveJobStatus::JobBatch
    end
    it "should create a redis set" do
      first_jobs.each do |job_id|
        expect(redis.smembers(batch_id)).to include job_id
      end
    end
  end

  describe "#add_jobs" do
    it "should add jobs to the set" do
      batch.add_jobs(job_ids: addl_jobs)
      total_jobs.each do |job_id|
        expect(ActiveJobStatus::JobBatch.find(batch_id: batch_id)).to \
          include job_id
      end
    end
  end

  describe "#completed?" do
    it "should be false when jobs are queued" do
      update_redis(id_array: total_jobs, job_status: :queued)
      expect(batch.completed?).to be_falsey
    end
    it "should be false when jobs are working" do
      update_redis(id_array: total_jobs, job_status: :working)
      expect(batch.completed?).to be_falsey
    end
    it "should be true when jobs are completed" do
      clear_redis(id_array: total_jobs)
      expect(batch.completed?).to be_truthy
    end
  end

  describe "::find" do
    it "should return an array of jobs when a batch exists" do
      expect(ActiveJobStatus::JobBatch.find(batch_id: batch_id)).to \
        be_an_instance_of Array
    end
    it "should return the correct jobs" do
      expect(ActiveJobStatus::JobBatch.find(batch_id: batch_id)).to \
        eq first_jobs
    end
    it "should return nil when no batch exists" do
      expect(ActiveJobStatus::JobBatch.find(batch_id: "45")).to eq []
    end
  end

  describe "expiring job" do
    it "should allow the expiration time to be set in seconds" do
      expect(ActiveJobStatus::JobBatch.new(batch_id: "newkey",
                                            job_ids: first_jobs,
                                            expire_in: 200000)).to \
            be_an_instance_of ActiveJobStatus::JobBatch
    end
    it "should expire" do
      ActiveJobStatus::JobBatch.new(batch_id: "expiry",
                                    job_ids: first_jobs,
                                    expire_in: 1)
      sleep 2
      expect(ActiveJobStatus::JobBatch.find(batch_id: "expiry")).to be_empty

    end
  end

  ##### HELPERS

  def update_redis(id_array: [], job_status: :queued)
    id_array.each do |id|
      redis.set(id, job_status.to_s)
    end
  end

  def clear_redis(id_array: [])
    id_array.each do |id|
      redis.del(id)
    end
  end
end

