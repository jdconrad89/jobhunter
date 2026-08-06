# frozen_string_literal: true

module Resumes
  class BuildSuggestionPrompt
    SYSTEM_PROMPT = <<~PROMPT.squish
      You are a career coach helping tailor resumes to specific job postings.
      Respond with valid JSON only, no markdown fences.
      Use this exact schema:
      {
        "summary_changes": ["string"],
        "skills_to_emphasize": ["string"],
        "skills_missing_or_weak": ["string"],
        "bullet_rewrites": [{"section": "string", "original": "string", "suggested": "string", "rationale": "string"}],
        "keywords_to_add": ["string"],
        "overall_match_score": 0
      }
      Be specific and actionable. Keep each list to at most 5 items.
      Reference actual resume content when suggesting bullet rewrites.
      overall_match_score is 0-100 indicating how well the resume matches the job.
    PROMPT

    # Keep prompts small to stay under OpenAI token-per-minute limits.
    MAX_JOB_DESCRIPTION_CHARS = 4_000
    MAX_RESUME_CHARS = 6_000

    def self.call(resume:, job_post:)
      new(resume: resume, job_post: job_post).call
    end

    def initialize(resume:, job_post:)
      @resume = resume
      @job_post = job_post
    end

    def call
      {
        system: SYSTEM_PROMPT,
        user: user_prompt
      }
    end

    private

    attr_reader :resume, :job_post

    def user_prompt
      <<~PROMPT
        ## Job Posting
        Title: #{job_post.title}
        Company: #{job_post.company.name}
        Location: #{job_post.location.presence || "Not specified"}
        Remote: #{job_post.remote ? "Yes" : "No"}

        Extracted skills from job description: #{job_post.extracted_skills.join(", ").presence || "None detected"}
        Experience requirement: #{job_post.extract_experience_requirement.presence || "Not specified"}
        Pay range: #{job_post.extract_pay_range.presence || "Not specified"}

        ### Job Description
        #{truncate_text(job_post.description, MAX_JOB_DESCRIPTION_CHARS)}

        ## Resume
        #{truncate_text(resume.extracted_text, MAX_RESUME_CHARS)}
      PROMPT
    end

    def truncate_text(text, max_chars)
      value = text.to_s.strip
      return "Not provided" if value.blank?
      return value if value.length <= max_chars

      "#{value[0, max_chars].rstrip}\n\n[Truncated for length]"
    end
  end
end
