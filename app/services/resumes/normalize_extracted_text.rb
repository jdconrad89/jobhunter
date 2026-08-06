# frozen_string_literal: true

module Resumes
  class NormalizeExtractedText
    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s
    end

    def call
      @text
        .lines
        .map { |line| normalize_line(line) }
        .join("\n")
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end

    private

    def normalize_line(line)
      normalized = line.strip
      return "" if normalized.empty?

      # Keep multi-space gaps as word boundaries so "J A S O N   C O N R A D"
      # becomes "JASON CONRAD" rather than "JASONCONRAD".
      normalized
        .split(/ {2,}/)
        .map { |part| normalize_part(part) }
        .reject(&:empty?)
        .join(" ")
    end

    def normalize_part(part)
      part = collapse_letter_spaced_caps(part.strip)
      part = split_camel_case(part)
      part = split_letter_digit_boundaries(part)
      part = WordSegmenter.call(part)
      part = fix_comma_spacing(part)
      collapse_spaces(part)
    end

    def collapse_spaces(text)
      text.gsub(/[^\S\n]+/, " ")
    end

    def fix_comma_spacing(text)
      text.gsub(/,(?=\S)/, ", ")
    end

    # Resume designers often letter-space section headers: "J A S O N" → "JASON"
    def collapse_letter_spaced_caps(text)
      text.gsub(/(?<![A-Za-z])(?:[A-Z]\s+){2,}[A-Z](?![A-Za-z])/) { |match| match.gsub(/\s+/, "") }
    end

    # Only split clear camelCase boundaries (lowercase immediately followed by uppercase).
    def split_camel_case(text)
      text.gsub(/(?<=[a-z])(?=[A-Z])/, " ")
    end

    def split_letter_digit_boundaries(text)
      text
        .gsub(/(?<=[a-zA-Z])(?=\d)/, " ")
        .gsub(/(?<=\d)(?=[a-zA-Z])/, " ")
    end
  end
end
