module ModelHelpers
  def create_user!(email: "test@example.com", password: "password", name: "Test User")
    User.create!(
      name: name,
      email: email,
      password: password,
      password_confirmation: password
    )
  end

  def create_company!(name: "Acme")
    Company.create!(name: name)
  end

  def create_job_search!(user:, job_title: "Ruby Engineer", timezone: "UTC", language_code: "en", remote: true, location: "Anywhere", board_relevance: [])
    JobSearch.create!(
      user: user,
      job_title: job_title,
      location: location,
      remote: remote,
      language_code: language_code,
      board_relevance: board_relevance,
      timezone: timezone
    )
  end

  # Lightweight stand-in for unit tests; JobScraper only reads attributes.
  def stub_job_search_for_job_scraper(job_title: "Ruby", location: nil, remote: nil, language_code: "en", board_relevance: [])
    instance_double(
      JobSearch,
      job_title: job_title,
      location: location,
      remote: remote,
      language_code: language_code,
      board_relevance: board_relevance,
    )
  end

  def create_job_post!(company:, job_search:, title: "Job", website: "https://example.com/job", description: "desc", location: "Anywhere", remote: true)
    JobPost.create!(
      company: company,
      job_search: job_search,
      title: title,
      website: website,
      description: description,
      location: location,
      remote: remote
    )
  end
end
