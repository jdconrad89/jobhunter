# frozen_string_literal: true

module ResumeSuggestionsHelper
  def resume_suggestion_status_label(suggestion)
    case suggestion.status
    when "pending"
      "Generating suggestions..."
    when "completed"
      "Suggestions ready"
    when "failed"
      "Suggestion generation failed"
    end
  end

  def resume_extraction_status_label(resume)
    case resume.extraction_status
    when "pending"
      "Extracting text..."
    when "completed"
      "Ready"
    when "failed"
      "Extraction failed"
    end
  end
end
