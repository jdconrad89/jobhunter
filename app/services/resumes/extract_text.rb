# frozen_string_literal: true

module Resumes
  class ExtractText
    def self.call(resume)
      new(resume).call
    end

    def initialize(resume)
      @resume = resume
    end

    def call
      raise "No file attached" unless resume.file.attached?

      text = extract_from_attachment
      resume.update!(extracted_text: text, extraction_status: :completed, extraction_error: nil)
    rescue StandardError => e
      resume.update_columns(extraction_status: Resume.extraction_statuses[:failed], extraction_error: e.message, updated_at: Time.current)
      raise
    end

    private

    attr_reader :resume

    def extract_from_attachment
      case resume.file.blob.content_type
      when "application/pdf"
        normalize_pdf_text(extract_pdf)
      when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        extract_docx.strip
      when "text/plain"
        resume.file.download.force_encoding("UTF-8").strip
      else
        raise "Unsupported file type"
      end
    end

    def normalize_pdf_text(text)
      NormalizeExtractedText.call(text)
    end

    def extract_pdf
      raw = extract_pdf_with_pdftotext
      raw = PdfTextExtractor.call(resume.file.download) if raw.blank?

      raw
    end

    def extract_pdf_with_pdftotext
      return unless pdftotext_available?

      Tempfile.create([ "resume", ".pdf" ]) do |pdf_file|
        pdf_file.binmode
        pdf_file.write(resume.file.download)
        pdf_file.flush

        Tempfile.create([ "resume", ".txt" ]) do |text_file|
          # Prefer reading-order extraction (better word spacing) over -layout.
          success = system("pdftotext", pdf_file.path, text_file.path, out: File::NULL, err: File::NULL)
          return unless success && File.size?(text_file.path)

          File.read(text_file.path).force_encoding("UTF-8")
        end
      end
    rescue StandardError
      nil
    end

    def pdftotext_available?
      system("which pdftotext > /dev/null 2>&1")
    end

    def extract_docx
      tempfile = Tempfile.new([ "resume", ".docx" ])
      begin
        tempfile.binmode
        tempfile.write(resume.file.download)
        tempfile.rewind
        doc = Docx::Document.open(tempfile.path)
        doc.paragraphs.map(&:text).join("\n")
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end
