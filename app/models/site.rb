class Site
  include Neo4j::ActiveNode

  after_create :set_default_values

  property :name, type: String
  property :url, type: String
  property :status, type: String
  property :indexed_pages, type: Integer
  property :created, type: DateTime
  property :updated, type: DateTime

  index :url

  has_many :in, :words, rel_class: AppearedIn

  validates_presence_of :url, :name
  validates_uniqueness_of :url, :name, case_sensitive: false


  def most_used_words(count)
    words = self.query_as(:s).match('w-[rel:`appeared_in`]->s').
                   order_by('rel.frequency DESC').limit(count).
                   pluck('w.word', 'rel.frequency').to_a
    words_map = []
    words.each do |word|
      words_map << [{ word: word[0], frequency: word[1] }]
    end
    words_map
  end


  def set_status(status)
    self.status = status
    self.save
  end


  def add_indexed_page
    self.indexed_pages = self.indexed_pages + 1
    self.save
  end


  protected


    def set_default_values
      self.created = Time.now
      self.status = "pending"
      self.indexed_pages = 0
      self.save
    end

  # end private
end