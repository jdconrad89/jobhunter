class JobScraper
  def initialize(job_search:)
    @job_title = job_search.job_title
    @location = job_search.location
    @remote = job_search.remote
    @language_code = job_search.language_code
    @board_relevance = Array(job_search.board_relevance)
    @job_boards_covered = []
    @number_of_jobs = job_search.number_of_jobs
  end

  def scrape
    response = []
    next_page_token = nil
    current_number_of_jobs = 0
    total_number_of_jobs = 0

    Rails.logger.info "Starting to scrape jobs for: #{@job_title}"

    target_count = @number_of_jobs.to_i.positive? ? @number_of_jobs : 100
    while response.length < target_count
      current_response = get_page_result(next_page_token: next_page_token)
      break if current_response[:jobs_results].nil?

      total_number_of_jobs += current_response[:jobs_results].length

      current_response[:jobs_results].each do |result|
        break if response.length >= target_count

        unless response.any? { |job| job[:title] == result[:title] && job[:company_name] == result[:company_name] }
          response << {
            title: result[:title],
            company_name: result[:company_name],
            company_website: result[:company_website],
            company_description: result[:company_description],
            url: get_url(result),
            description: result[:description],
            location: result[:location],
            remote: result[:remote],
            posted_at: parse_posted_date(result[:posted_at])
          }
        end
      end

      Rails.logger.info "Scraping... #{response.length} unique jobs out of #{total_number_of_jobs} jobs scraped."

      current_number_of_jobs = response.length
      break if current_response[:serpapi_pagination].nil?
      next_page_token = current_response[:serpapi_pagination][:next_page_token]
    end

    response
  end

  private

  def get_page_result(next_page_token: nil)
    search = GoogleSearch.new(request_params(next_page_token: next_page_token))
    search.get_hash
  end

  def request_params(next_page_token: nil)
    params = {
      engine: 'google_jobs',
      q: @job_title,
      hl: @language_code,
      no_cache: true,
      api_key: ENV['SERPAPI_API_KEY']
    }

    params.merge!(next_page_token: next_page_token) if next_page_token
    params.merge!(location: @location) if @location
    params.merge!(ltype: get_remote_code(@remote)) if @remote != nil
    params
  end

  def get_url(result)
    sorted_links = sort_links_by_relevance(result[:apply_options])
    return nil if sorted_links.empty?

    uri = URI.parse(sorted_links.first[:link])
    query_params = CGI.parse(uri.query.to_s)
    filtered_params = query_params.reject { |key| key.start_with?('utm') }
    uri.query = URI.encode_www_form(filtered_params)

    uri.to_s
  end

  def sort_links_by_relevance(apply_options)
    return [] if apply_options.nil?

    apply_options.sort_by do |option|
      next Float::INFINITY if option[:title].nil?
      @job_boards_covered << option[:title] unless @job_boards_covered.include?(option[:title])

      normalized_title = option[:title].downcase.gsub(/\s+/, '')
      board_relevance_normalized.index(normalized_title) || Float::INFINITY
    end
  end

  def board_relevance_normalized
    @board_relevance_normalized ||= @board_relevance.map do |board|
      board.downcase.gsub(/\s+/, '')
    end
  end

  def get_remote_code(remote)
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

    case posted_at.downcase
    when /(\d+)\s+days?/
      $1.to_i.days.ago
    when /(\d+)\s+weeks?/
      $1.to_i.weeks.ago
    when /(\d+)\s+months?/
      $1.to_i.months.ago
    when /today/
      Time.current
    when /yesterday/
      1.day.ago
    else
      Time.current
    end
  end
end 