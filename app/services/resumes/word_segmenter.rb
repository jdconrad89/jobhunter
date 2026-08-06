# frozen_string_literal: true

module Resumes
  # Segments glued PDF tokens using a dictionary, without inserting spaces inside
  # known whole words.
  class WordSegmenter
    DICTIONARY = %w[
      a ability about across address advanced agile align alignment all and
      annually api apis app application applications architecture as assist at
      automated aws back backend basics become bedding board boarded boarding
      boosting building built by capabilities client clients cloud codebase code
      collaborating collaborated collaboration commerce communication company
      compliance conducted consuming continue continuous contractors cost
      coverage creating critical crm cross culture custom debt deliver
      demonstrated design designed developers development direct documentation
      documented domain drive driven driving ecommerce education efficiency
      efficient elevating eliminating employment end engineer engineering
      enhancing ensuring experience experienced expertise features finally fit
      focused for fostering full functional functionalities goals greenfield
      growth higher history honing hours improving in increasing initiatives
      integrated integrating integration interactive into interviews invest
      issues javascript job key knowledge lab leadership leading learn learning
      learning leveraging like maintenance management manual measures members
      mentoring mentorship message mixing months more move native nearly new
      object of on online optimization optimizing or oriented other our over
      performance planning proactive processes proficiency program programming
      project projects protocols proven provided purchase qa quality queues
      rails raleigh roadmap roughly ruby saas sales saving scalable scripts
      security senior sessions seven shopify significantly skills software
      solutions specializing spearheaded stack starts strategies students
      substantial supporting system systems team teams technical test testing
      the then they thorough through time to track troubleshooting turing using
      user usability while with workflows years record research enhance improved
      resource effective maintained developed developer releases reducing scripts
      assist across quality ecommerce native onboarded postgresql javascript
      process processes measure measures initiative initiative
      administer administered application automated capabilities collaborated
      committed communication continuous contractors demonstrated documented
      eliminating enhancing experienced functionalities implemented increasing
      initiatives integrated integrating mentorship optimization organizational
      performance proficiency rightsizing satisfaction significantly specializing
      spearheaded substantial supporting troubleshooting
    ].map(&:downcase).uniq.sort_by { |word| -word.length }.freeze

    MIN_TOKEN_LENGTH = 6

    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s
    end

    def call
      @text.gsub(/[A-Za-z][A-Za-z]{#{MIN_TOKEN_LENGTH - 1},}/) do |token|
        segment_token(token)
      end
    end

    private

    def segment_token(token)
      return token if DICTIONARY.include?(token.downcase)

      parts = break_words(token.downcase)
      return token if parts.nil? || parts.one?

      rejoin_with_original_casing(token, parts)
    end

    def break_words(token)
      length = token.length
      dp = Array.new(length + 1)
      dp[0] = []

      (1..length).each do |i|
        DICTIONARY.each do |word|
          start = i - word.length
          next if start.negative?
          next unless dp[start]
          next unless token[start, word.length] == word

          candidate = dp[start] + [ word ]
          dp[i] = candidate if dp[i].nil? || candidate.size < dp[i].size
        end
      end

      return nil unless dp[length]
      return nil if dp[length].any? { |part| part.length < 2 && part != "a" }

      dp[length]
    end

    def rejoin_with_original_casing(original, parts)
      offset = 0
      parts.map do |part|
        slice = original[offset, part.length]
        offset += part.length
        slice
      end.join(" ")
    end
  end
end
