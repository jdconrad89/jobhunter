module JobPosts
  class CreateManual
    Result = Data.define(:success?, :job_post, :errors)

    def self.call(user:, attributes:)
      new(user: user, attributes: attributes).call
    end

    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      company_name = @attributes.delete(:company_name).to_s.strip
      if company_name.blank?
        job_post = JobPost.new(@attributes)
        job_post.errors.add(:company, "name can't be blank")
        return failure(job_post)
      end

      company = Company.find_or_create_by(name: company_name)
      unless company.persisted?
        job_post = JobPost.new(@attributes.merge(company: company))
        job_post.errors.add(:company, company.errors.full_messages.to_sentence.presence || "is invalid")
        return failure(job_post)
      end

      job_post = JobPost.new(@attributes.merge(company: company, job_search: manual_job_search))
      if job_post.save
        Result.new(success?: true, job_post: job_post, errors: nil)
      else
        failure(job_post)
      end
    end

    private

    def manual_job_search
      @user.job_searches.find_or_create_by!(job_title: JobSearch::MANUAL_JOB_SEARCH_TITLE) do |job_search|
        job_search.language_code = "en"
        job_search.timezone = Time.zone.name
        job_search.location = "Anywhere"
        job_search.remote = true
        job_search.number_of_jobs = 0 if job_search.respond_to?(:number_of_jobs=)
      end
    end

    def failure(job_post)
      Result.new(success?: false, job_post: job_post, errors: job_post.errors)
    end
  end
end
