class CrawlerController < ApplicationController

  def index
    @words = []
    @site_name = "Oops, address no valid!"
    @site_url = "YOLO"
    if request.GET[:test]
      url = request.GET[:url]
    else
      url = request.POST[:url]
    end
    if !url.blank?
      url = "http://#{sanitize_url(url)}"
      if name = get_site_name(url)
        site = Site.find_by(url: url)
        if site.nil?
          site = Site.create(url: url, name: name)
          if site
            init_crawl(url)
          end
        end
        @words = site.most_used_words(100)
        @site_name = site.name
        @site_url = site.url
      end
    end
  end


  private


  # Url relation functions
  def valid_url(url)
    uri = URI.parse(url)
    uri.kind_of?(URI::HTTP)
  rescue URI::InvalidURIError
    false
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


  def get_root_url(url)
    if uri = URI.parse(url)
      uri.userinfo = nil
      uri.path = ''
      uri.fragment = nil
      if !uri.host.nil?
        return uri.host
      end
    end
    return false
  end


  # Crawl related functions
  def init_crawl(url)
    user_agent = "PolyglotNinja"
    uri = sanitize_url(url)
    if Site.find_by(url: uri).blank?
      CobwebCrawler.new(:cache => 600, :valid_mime_types => 'text/*',
                        :thread_count => 10).crawl(url) do |page|
        if page[:mime_type] == 'text/html'
          text = get_plain_text(page)
          words_hash = get_word_frequencies(text)
          process_words(words_hash, url)
        end
      end
    else
      return false
    end
  end


  # Header info related functions
  def get_site_name(url)
    if page = Nokogiri::HTML(RestClient.get(url))
      name = page.css("title")[0].text
      if name.blank?
        name = "Undefined"
      end
      return name
    end
  rescue Exception
    return false
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
