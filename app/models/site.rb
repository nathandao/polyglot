class Site
  include Neo4j::ActiveNode

  property :name, type: String
  property :url, type: String
  property :created, type: DateTime
  property :updated, type: DateTime
  has_many :in, :words, rel_class: AppearedIn
  index :url

  validates_presence_of :url, :name
  validates_uniqueness_of :url, :name, case_sensitive: false

  def most_used_words(count)
    return self.query_as(:s).match('w-[rel:`appeared_in`]->s').
           order_by('rel.frequency DESC').limit(count).
           pluck('w.word', 'rel.frequency').to_a
  end
end