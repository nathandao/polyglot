class Phrase
  include Neo4j::ActiveNode

  property :phrase, type: String
  index :phrase

  has_many :in, :words, rel_class: Means

  validates_presence_of :phrase
  validates_uniqueness_of :phrase, case_sensitive: false
  validate :set_sanitized_phrase

  protected

    def set_sanitized_phrase
      self.phrase = self.phrase.downcase if self.phrase
    end

end
