class Word
	before_validate :sanitize_word

  include Neo4j::ActiveNode
  property :word, type: String

  validates_presence_of :word

  protected

  def sanitize_word
  	self.word = self.word.downcase
  end
end