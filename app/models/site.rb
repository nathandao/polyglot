class Site
  include Neo4j::ActiveNode
  property :name, type: String
  property :url, type: String
  property :created, type: DateTime
  property :updated, type: DateTime

  validates_presence_of :url, :name
  #TODO: Add validations
end
