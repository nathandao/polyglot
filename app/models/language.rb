class Language
  include Neo4j::ActiveNode

  property :name, type: String
  property :locale, type: String

  has_many :in, :words, rel_class: BelongsTo
  has_many :in, :phrases, rel_class: BelongsTo

  validates_presence_of :url, :name
  validates_uniqueness_of :url, :name, case_sensitive: false
end
