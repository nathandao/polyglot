class WordProcessJob
  @queue = :word_process_job

  class << self

    def perform(data)
      words = data['words']
      url = data['url']
      process(words, url)
    end

    private

      def process(words, data)
        if site_node = Site.find_by(url: url)
          words.each do |word, frequency|
            word = word.downcase
            word_node = Word.find_by(word: word)
            if word_node.nil? && word.length > 0
              word_node = Word.create(word: word)
              AppearedIn.create(from_node: word_node, to_node: site_node,
                                frequency: frequency)
            else
              word_node = Word.find_by(word: word)
            end

            if !word_node.nil?
              rel = word_node.get_site_rel(site_node)
              if rel.nil?
                AppearedIn.create(from_node: word_node, to_node: site_node,
                                  frequency: frequency)
              else
                rel.add(frequency)
                rel.save
              end
            end
          end
        end
      end

    #end private
  end
end