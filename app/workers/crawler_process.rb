class CrawlerProcess
  @queue = :crawler_queue

  def self.perform(url)
    user_agent = "PolyglotNinja"
    uri = sanitize_url(url)
    crawler = CobwebCrawler.new(:cache => 600,
                                :valid_mime_types => 'text/html',
                                :thread_count => 10)
    if Site.find_by(url: uri).blank?
      crawler.crawl(url) do |page|
        if page[:mime_type] == 'text/html'
          text = get_plain_text(page)
          words_hash = get_word_frequencies(text)
          process_words(words_hash, url)
        end
      end
    end
  end

  def sanitize_url(url)
    url = url.downcase
    if !get_root_url(url)
      url = "http://#{url}"
    end
    if url = get_root_url(url)
      return url
    else
      return false
    end
  end

  # Text content related functions
  def get_plain_text(page)
    html = Nokogiri::HTML(page[:body])
    text = (html.xpath '//p/text()').to_s
    return text.scan(/[a-z]+/i)
  end


  def get_word_frequencies(words)
    Hash[
      words.group_by(&:downcase).map{ |word,instances|
        [word,instances.length] }.sort_by(&:last).reverse
    ]
  end


  def process_words(words_hash, url)
    site_node = Site.find_by(url: url)
    words_hash.each do |word, frequency|
      word = word.downcase
      word_node = Word.find_by(word: word)
      if word_node.nil? && word.length > 3 && word.length <= 15
        word_node = Word.create(word: word)
        AppearedIn.create(from_node: word_node, to_node: site_node,
                          frequency: frequency)
      else
        word_node = Word.find_by(word: word)
      end
      if !word_node.nil?
        rel = word_node.get_site_rel(site_node)
        if rel.nil?
          AppearedIn.create(from_node: word_node, to_node: site_node,
                            frequency: frequency)
        else
          rel.add(frequency)
          rel.save
        end
      end
    end
  end
end