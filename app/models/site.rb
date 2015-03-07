class Site
  include Neo4j::ActiveNode

  after_create :add_created_date

  property :name, type: String
  property :url, type: String
  property :pages_indexed, type: Integer
  property :created, type: DateTime
  property :updated, type: DateTime
  index :url

  has_many :in, :words, rel_class: AppearedIn

  validates_presence_of :url, :name
  validates_uniqueness_of :url, :name, case_sensitive: false

  def most_used_words(count)
    processed_words = []
    words = self.query_as(:s).match('w-[rel:`appeared_in`]->s').
                   order_by('rel.frequency DESC').limit(count).
                   pluck('w.word', 'rel.frequency').to_a
    words_map = []
    words.each do |word|
      words_map << [{ word: word[0], frequency: word[1] }]
    end
    return words_map
  end


  private

    def add_created_date
      self.created = Time.now
    end
end