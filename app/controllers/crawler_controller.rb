require 'nokogiri'

class CrawlerController < ApplicationController

  def index
    # TODO: Replace with custom site_url parameter
    url = "http://guynathan.com"
    uri = sanitize_url(url)
    url = "https://#{uri}"

    if uri
      if Site.find_by(url: url).blank?
        init_crawl(url)
      else
        # Site already indexed!!!
        # TODO: List top words from database
      end
      #puts "Finished Crawl with #{statistics[:page_count]} pages"
      @words = []
    else
      return false
    end
  end

  private


  # Crawl related function
  def init_crawl(url)
    user_agent = "PolyglotNinja"
    if Site.find_by(url: url).blank?
      CobwebCrawler.new(:cache => 600, :valid_mime_types => 'text/*').crawl(url) do |page|
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


  # Url related functions
  def sanitize_url(url)
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


  # Header info related functions
  def get_site_title(url)
    page = Nokogiri::HTML(RestClient.get(url))
    title = !page.css("title")[0].text
    if !page.css("title")[0].text.blank?
      return title
    end
    return "Undefined"
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
    words_hash.each do |word, frequency|
      word = word.downcase
      # TODO: Improve word validation logic
      if Word.find_by(word: word).nil? && word.length > 3 && word.length <= 10
        Word.create(word: word)
      end
    end
  end
end
