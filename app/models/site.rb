class Site
  include Neo4j::ActiveNode
  property :name, type: String
  property :url, type: String

  has_many :in, :words, origin: :site
end
