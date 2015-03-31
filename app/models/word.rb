class Word
  include Neo4j::ActiveNode

  property :word, type: String
  index :word
  has_many :out, :sites, rel_class: AppearedIn
  validates_presence_of :word
  validates_uniqueness_of :word, case_sensitive: false
  validate :set_sanitized_word


  def get_site_rel(site)
    return self.query_as(:w).
           match("w-[rel:`appeared_in`]->(:Site {url: \"#{site.url}\"})").
           pluck(:rel).first
  end


  def translate(target)
    translated = find_local_translation(self.word, target)
    return translated if translated
    create_translation(self.word, target)
  end


  protected


    def set_sanitized_word
    	self.word = self.word.downcase if self.word
    end


  private


    def find_local_translation(word, target)
      cypher = "match (w:Word { word: '{word}' }),
                      (target:Language { locale: '{target}' }),
                      (w)-[:means]->(translation)-[:belongs_to]->(target)
                return translation"
      Neo4j::Session.query(cypher, word: word, target: target)
    end


    def create_translation(word, target)
      bing_id = ENV['BING_CLIENT_ID']
      bing_sercet = ENV['BING_CLIENT_SECRET']

      if bing_id && bing_sercet
        translator = BingTranslator.new(bing_id, bing_sercet)
        locale = translator.detect(word)
        translated = translator.translate(word, :from => locale, :to => target)
        tr_type = 'Word'
        tr_type = 'Phrase' if translated.length > 1
        cypher = "match (w:Word { word: '#{word}' })
                  merge (tr:#{tr_type} { #{tr_type.downcase}: '#{translated}' })
                  merge (l:Language { locale: '#{locale}' })
                  merge (t:Language { locale: '#{target}' })
                  merge (w)-[:belongs_to]->(l)
                  merge (w)-[:means]->(tr)-[:belongs_to]->(t)
                  return tr"
        return Neo4j::Session.query(cypher)
      end
      false
    rescue Exception
      return false
    end

  # End private

end