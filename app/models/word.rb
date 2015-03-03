class Word
  include Neo4j::ActiveNode
  property :word, type: String
  index :word

  has_many :out, :sites, rel_class: AppearedIn

  validates_presence_of :word

  validates_uniqueness_of :word, case_sensitive: false

  validate :set_sanitized_word

  protected

  def set_sanitized_word
  	self.word = self.word.downcase if self.word
  end
end