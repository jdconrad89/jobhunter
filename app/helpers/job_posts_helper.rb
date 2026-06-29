module JobPostsHelper
  def safe_job_post_website(job_post)
    JobPosts::SafeUrl.http_url(job_post.website)
  end

  def job_post_external_link(job_post, css_class:, &block)
    url = safe_job_post_website(job_post)
    if url
      link_to(url, target: "_blank", rel: "noopener noreferrer", class: css_class, &block)
    else
      tag.span(class: css_class, &block)
    end
  end

  def job_post_description_with_highlighted_pay(job_post)
    return "" if job_post.description.blank?

    formatted = simple_format(job_post.description)
    pay_range = job_post.extract_pay_range
    html = if pay_range.blank?
      formatted
    else
      escaped = Regexp.escape(pay_range)
      formatted.gsub(Regexp.new("(#{escaped})"), '<span class="pay-range-highlight">\1</span>')
    end

    sanitize(html, tags: %w[p br span], attributes: %w[class])
  end
end
