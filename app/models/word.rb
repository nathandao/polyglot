class Word
  include Neo4j::ActiveNode
  property :word, type: String

  validates_presence_of :word
  #TODO: Add validations
end
