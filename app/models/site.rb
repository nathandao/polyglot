include ActionView::Helpers

class Site
	before_validation :sanitize_url

  include Neo4j::ActiveNode
  property :name, type: String
  property :url, type: String
  property :created, type: DateTime
  property :updated, type: DateTime

  validates_presence_of :url, :name

  protected

  def sanitize_url
  	self.url = sanitize_url(self.url)
  end
end