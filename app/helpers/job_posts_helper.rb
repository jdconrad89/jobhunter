module JobPostsHelper
  def job_post_description_with_highlighted_pay(job_post)
    return "" if job_post.description.blank?

    formatted = simple_format(job_post.description)
    pay_range = job_post.extract_pay_range
    return formatted if pay_range.blank?

    escaped = Regexp.escape(pay_range)
    formatted.gsub(Regexp.new("(#{escaped})"), '<span class="pay-range-highlight">\1</span>')
  end
end

