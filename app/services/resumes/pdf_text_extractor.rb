# frozen_string_literal: true

module Resumes
  class PdfTextExtractor
    LINE_HEIGHT_FACTOR = 0.6
    CHAR_GAP_FRACTION = 0.7
    CHAR_GAP_MULTIPLIER = 2.5
    MIN_THRESHOLD_FACTOR = 0.05
    MAX_THRESHOLD_FACTOR = 0.35

    def self.call(pdf_data)
      new(pdf_data).call
    end

    def initialize(pdf_data)
      @pdf_data = pdf_data
    end

    def call
      reader = PDF::Reader.new(StringIO.new(@pdf_data))
      reader.pages.map { |page| extract_page(page) }.join("\n\n").strip
    end

    private

    def extract_page(page)
      # Character-level runs so we can choose word boundaries from gap clusters.
      runs = page.runs(merge: false)
      return "" if runs.empty?

      group_runs_by_line(runs)
        .map { |line_runs| build_line_text(line_runs) }
        .reject(&:blank?)
        .join("\n")
    end

    def group_runs_by_line(runs)
      sorted = runs.sort_by { |run| [ -run.y, run.x ] }
      lines = []
      current_line = []
      current_y = nil
      tolerance = nil

      sorted.each do |run|
        if current_y.nil? || (run.y - current_y).abs > tolerance
          lines << current_line.sort_by(&:x) if current_line.any?
          current_line = [ run ]
          current_y = run.y
          tolerance = run.font_size * LINE_HEIGHT_FACTOR
        else
          current_line << run
        end
      end

      lines << current_line.sort_by(&:x) if current_line.any?
      lines
    end

    def build_line_text(runs)
      return "" if runs.empty?
      return runs.first.text if runs.one?

      threshold = space_threshold(runs)
      text = +runs.first.text

      runs.each_cons(2) do |previous, current|
        gap = current.x - previous.endx
        text << " " if gap > threshold
        text << current.text
      end

      text
    end

    # Estimate typical inter-character gaps from the lower portion of gaps, then
    # place the word-space threshold between the character-gap and word-gap clusters.
    # This avoids both extremes: mid-word spaces and fully glued words.
    def space_threshold(runs)
      font_size = runs.map(&:font_size).max
      gaps = runs.each_cons(2).map { |previous, current| current.x - previous.endx }
      positive = gaps.select { |gap| gap > 0 }.sort

      return font_size * 0.15 if positive.size < 3

      lower_count = [ (positive.size * CHAR_GAP_FRACTION).ceil, positive.size - 1 ].min
      lower = positive[0...lower_count]
      char_gap = lower[lower.size / 2]
      threshold = char_gap * CHAR_GAP_MULTIPLIER

      threshold.clamp(font_size * MIN_THRESHOLD_FACTOR, font_size * MAX_THRESHOLD_FACTOR)
    end
  end
end
