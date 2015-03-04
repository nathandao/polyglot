class Word
  include Neo4j::ActiveNode

  property :word, type: String
  index :word

  has_many :out, :sites, rel_class: AppearedIn

  validates_presence_of :word
  validates_uniqueness_of :word, case_sensitive: false
  validate :set_sanitized_word

  def get_site_rel(site)
    return word_node.query_as(:w).
           match("w-[rel:`appeared_in`]->(:Site {url: \"#{site.url}\"})").
           pluck(:rel).first
  end

  protected

  def set_sanitized_word
  	self.word = self.word.downcase if self.word
  end
end