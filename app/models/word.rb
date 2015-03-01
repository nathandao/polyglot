class Word
  include Neo4j::ActiveNode
  property :word, type: String

  has_many :out, :sites, type: :appears_in
  #TODO: Add validations
end
