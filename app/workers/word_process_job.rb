class WordProcessJob
  @queue = :word_process_job

  class << self

    def perform(data)
      words = data['words']
      url = data['url']
      process(words, url)
    end


    private


      def process(word_data, url)
        cypher = construct_cypher(word_data, url)
        Neo4j::Session.query(cypher, word_data: word_data)
      end


      def construct_word_data(words)
        word_data = '['
        first = true
        words.each do | word, frequency |
          word = word.to_s.downcase
          word_data += ',' if first == false
          first = false
          word_data += "{word:'#{word}', frequency: #{frequency}}"
        end
        word_data += ']'
        word_data
      end


      def construct_cypher(word_data, url)
        "match (s:Site { url: '#{url}' })
         foreach(n IN {word_data}|
            merge (w:Word { word: n.word })
            merge (w)-[r:appeared_in]->(s)
            on create set r.frequency = n.frequency
            on match set r.frequency = r.frequency + n.frequency
         )"
      end

    # End private

  end
end