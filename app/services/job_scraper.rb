class JobScraper
  def initialize(job_search:)
    @job_title = job_search.job_title
    @location = job_search.location
    @remote = job_search.remote
    @language_code = job_search.language_code
    @board_relevance = Array(job_search.board_relevance)
  end

  def scrape
    response = []
    next_page_token = nil
    total_number_of_jobs = 0

    Rails.logger.info "Starting to scrape jobs for: #{@job_title}"

    # TODO: Add logic to have a return number of jobs preference on job search separate from the
    # existing number_of_jobs field that tracks number of jobs a search has found
    while response.length < 100
      current_response = serpapi_response(next_page_token: next_page_token)
      break if current_response[:jobs_results].nil?

      total_number_of_jobs += current_response[:jobs_results].length

      current_response[:jobs_results].each do |result|
        break if response.length >= 100

        unless response.any? { |job| job[:title] == result[:title] && job[:company_name] == result[:company_name] }
          response << {
            title: result[:title],
            company_name: result[:company_name],
            company_website: result[:company_website],
            company_description: result[:company_description],
            url: apply_option_url(result),
            description: result[:description],
            location: result[:location],
            remote: result[:remote],
            posted_at: parse_posted_date(result[:posted_at])
          }
        end
      end

      Rails.logger.info "Scraping... #{response.length} unique jobs out of #{total_number_of_jobs} jobs scraped."

      break if current_response[:serpapi_pagination].nil?
      next_page_token = current_response[:serpapi_pagination][:next_page_token]
    end

    response
  end

  private

  def serpapi_response(next_page_token: nil)
    search = GoogleSearch.new(request_params(next_page_token: next_page_token))
    search.get_hash
  end

  def request_params(next_page_token: nil)
    params = {
      engine: "google_jobs",
      q: @job_title,
      hl: @language_code,
      no_cache: true,
      api_key: ENV["SERPAPI_API_KEY"]
    }

    params.merge!(next_page_token: next_page_token) if next_page_token
    params.merge!(location: @location) if @location
    params.merge!(ltype: remote_type(@remote)) if @remote != nil
    params
  end

  def apply_option_url(result)
    sorted_links = sort_apply_options_by_board_relevance(result[:apply_options])
    return nil if sorted_links.empty?

    uri = URI.parse(sorted_links.first[:link])
    query_params = CGI.parse(uri.query.to_s)
    filtered_params = query_params.reject { |key| key.start_with?("utm") }
    uri.query = URI.encode_www_form(filtered_params)

    uri.to_s
  end

  def sort_apply_options_by_board_relevance(apply_options)
    return [] if apply_options.nil?

    boards_index = board_relevance_normalized
    apply_options.sort_by do |option|
      next Float::INFINITY if option[:title].nil?

      normalized_title = option[:title].downcase.gsub(/\s+/, "")
      boards_index.index(normalized_title) || Float::INFINITY
    end
  end

  def board_relevance_normalized
    @board_relevance_normalized ||= @board_relevance.map do |board|
      board.downcase.gsub(/\s+/, "")
    end
  end

  def remote_type(remote)
    case remote
    when true
      1
    when false
      0
    else
      nil
    end
  end

  def parse_posted_date(posted_at)
    return nil if posted_at.nil?

    lowercased_posted_at = posted_at.downcase

    if (day_count = lowercased_posted_at[/(\d+)\s+days?/, 1])
      day_count.to_i.days.ago
    elsif (week_count = lowercased_posted_at[/(\d+)\s+weeks?/, 1])
      week_count.to_i.weeks.ago
    elsif (month_count = lowercased_posted_at[/(\d+)\s+months?/, 1])
      month_count.to_i.months.ago
    elsif lowercased_posted_at.match?(/today/)
      Time.current
    elsif lowercased_posted_at.match?(/yesterday/)
      1.day.ago
    else
      Time.current
    end
  end
end
