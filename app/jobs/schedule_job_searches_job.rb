class ScheduleJobSearchesJob < ApplicationJob
  queue_as :default

  # Finds JobSearch records whose daily runtime matches the current 15-minute
  # slot (in each search's timezone) and enqueues a JobScraperJob for each.
  def perform(at = Time.current)
    due = JobSearch.due_for_run(at)

    Rails.logger.info "ScheduleJobSearchesJob: enqueueing #{due.size} job search(es) for #{at}"

    due.each do |job_search|
      JobScraperJob.perform_later(job_search.id)
    end
  end
end
