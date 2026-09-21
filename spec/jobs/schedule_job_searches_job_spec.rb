require "rails_helper"

RSpec.describe ScheduleJobSearchesJob, type: :job do
  let(:zone) { ActiveSupport::TimeZone[JobSearch::DEFAULT_TIMEZONE] }

  it "enqueues JobScraperJob for each search due in the current 15-minute slot" do
    user = create_user!(email: "schedule@example.com")
    due = create_job_search!(
      user: user,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 9, 15)
    )
    create_job_search!(
      user: user,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 10, 0)
    )

    expect {
      described_class.perform_now(zone.local(2026, 9, 21, 9, 15))
    }.to have_enqueued_job(JobScraperJob).with(due.id).exactly(:once)
  end

  it "enqueues nothing when no searches match the slot" do
    user = create_user!(email: "schedule_none@example.com")
    create_job_search!(
      user: user,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 10, 0)
    )

    expect {
      described_class.perform_now(zone.local(2026, 9, 21, 9, 15))
    }.not_to have_enqueued_job(JobScraperJob)
  end

  it "skips manual searches even when runtime matches" do
    user = create_user!(email: "schedule_manual@example.com")
    create_job_search!(
      user: user,
      job_title: JobSearch::MANUAL_JOB_SEARCH_TITLE,
      timezone: JobSearch::DEFAULT_TIMEZONE,
      runtime: Time.zone.local(2000, 1, 1, 9, 15)
    )

    expect {
      described_class.perform_now(zone.local(2026, 9, 21, 9, 15))
    }.not_to have_enqueued_job(JobScraperJob)
  end
end
