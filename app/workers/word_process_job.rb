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
        #word_data = construct_word_data(words)
        #word_data = [{word: "nathan", frequency: 2}, {word: "nathan2", frequency: 2},{word: "nathan3", frequency: 2},{word: "nathan4", frequency: 2},{word: "nathan5", frequency: 2}]
        cypher = construct_cypher(word_data, url)
        Neo4j::Session.query(cypher).params(word_data: word_data)
        #Neo4j::Session.query(cypher, word_data: word_data)
      end


      def construct_word_data(words)
        word_data = '['
        first = true
        words.each do | word, frequency |
          word = word.to_s.downcase
          if first == true
            first = false
          else
            word_data += ','
          end
          word_data += "{word:'#{word}', frequency: #{frequency}}"
        end
        word_data += ']'
        return word_data
      end


      def construct_cypher(word_data, url)
        cypher = "match (s:Site { url: '#{url}' })
          foreach(n IN {word_data}|
            merge (w:Word { word: n.word })
            merge (w)-[r:appeared_in]->(s)
            on create set r.frequency = n.frequency
            on match set r.frequency = r.frequency + n.frequency
          )"
        return cypher
      end

# => Old imlementation
#      def process(words, url)
#        if site_node = Site.find_by(url: url)
#          words.each do |word, frequency|
#            word = word.downcase
#            word_node = Word.find_by(word: word)
#            if word_node.nil? && word.length > 0
#              word_node = Word.create(word: word)
#              AppearedIn.create(from_node: word_node, to_node: site_node,
#                                frequency: frequency)
#            else
#              word_node = Word.find_by(word: word)
#            end
#
#            if !word_node.nil?
#              rel = word_node.get_site_rel(site_node)
#              if rel.nil?
#                AppearedIn.create(from_node: word_node, to_node: site_node,
#                                  frequency: frequency)
#              else
#                rel.add(frequency)
#                rel.save
#              end
#            end
#          end
#        end
#      end

    #end private
  end
end