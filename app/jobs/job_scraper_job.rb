class JobScraperJob < ApplicationJob
  queue_as :default

  def perform(job_search_id)
    job_search = JobSearch.find_by(id: job_search_id)
    unless job_search
      Rails.logger.info "JobScraperJob: JobSearch id=#{job_search_id} not found, skipping"
      return
    end

    Time.zone = job_search.timezone

    Rails.logger.info "Starting job search for: #{job_search.job_title} in #{job_search.location}"

    begin
      scraper = JobScraper.new(job_search: job_search)
      results = scraper.scrape

      results.each do |job_data|
        next if job_data[:company_name].blank? || job_data[:url].blank?

        company = Company.find_or_create_by!(name: job_data[:company_name]) do |c|
          c.description = job_data[:company_description]
        end

        JobPost.find_or_create_by!(
          job_search: job_search,
          title: job_data[:title],
          company: company,
          website: job_data[:url]
        ) do |post|
          post.description = job_data[:description]
          post.location = job_data[:location]
          post.remote = job_data[:remote]
          post.posted_at = job_data[:posted_at]
        end
      end

      Rails.logger.info "Successfully completed job search for: #{job_search.job_title}"
    rescue StandardError => e
      Rails.logger.error "Error during job search for #{job_search.job_title}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      raise
    end
  end
end
