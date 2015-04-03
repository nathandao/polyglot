class Site
  include Neo4j::ActiveNode

  after_create :set_default_values
  after_initialize :santize_data

  property :name, type: String
  property :url, type: String
  property :status, type: String
  property :indexed_pages, type: Integer
  property :created, type: DateTime
  property :updated, type: DateTime

  index :url

  has_many :in, :words, rel_class: AppearedIn

  validates_presence_of :url
  validates_uniqueness_of :url, case_sensitive: false
  validate :valid_site


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


  def init_crawl
    url = self.url
    crawler = Cobweb.new(:follow_redirects => true,
                         :valid_mime_types => ['text/html'],
                         :direct_call_process_job => true,
                         :processing_queue => 'PolyglotCrawlProcessJob',
                         :crawl_finished_queue => 'PolyglotCrawlFinishJob',
                         :obey_robots => true,
                         :crawl_limit_by_page => true,
                         :redirect_limit => 10)
    crawler.start(url)
  end


  def is_valid?
    name = get_site_name(sanitize_url(self.url))
    return true if name
    false
  end


  def sanitize_site_url
    self.url = sanitize_url(self.url)
  end


  protected

    def valid_site
      name = get_site_name(self.url)
      self.errors.add("invalid site url") if !name
    end


    def set_default_values
      self.name = get_site_name(self.url)
      self.created = Time.now
      self.status = "pending"
      self.indexed_pages = 0
      self.save
    end


    def santize_data
      self.url = sanitize_url(self.url)
    end


  private


    def sanitize_url(url)
      url = url.downcase
      url = "http://#{url}" if !get_root_url(url)
      return url if url = get_root_url(url)
      false
    end


    def get_root_url(url)
      if uri = URI.parse(url)
        uri.userinfo = nil
        uri.path = ''
        uri.fragment = nil
        return uri.host if !uri.host.nil?
      end
      false
    end


    def get_site_name(url)
      if page = Nokogiri::HTML(RestClient.get(url))
        name = page.css("title")[0].text
        name = "Undefined" if name.blank?
        return name
      end
    rescue Exception
      false
    end

  # end private
end