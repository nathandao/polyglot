require 'nokogiri'

class CrawlerController < ApplicationController
  include CrawlerHelper

  def index
    # TODO: Replace with custom site_url parameter
    url = "exove.com"
    uri = sanitize_url(url)
    url = "http://#{uri}"

    if uri
      site = Site.find_by(url: url)
      if site.nil?
        name = get_site_name(url)
        site = Site.create(url: url, name: name)
        if site
          init_crawl(url)
        end
      end
      @words = site.query_as(:s).match('w-[rel:`appeared_in`]->s').order_by('rel.frequency DESC').limit(100).pluck('w.word', 'rel.frequency').to_a
      @site = site
    else
      @words = []
      @site = "Oops, address no valid!"
    end
  end

  private


  # Crawl related function
  def init_crawl(url)
    user_agent = "PolyglotNinja"
    uri = sanitize_url(url)
    if Site.find_by(url: uri).blank?
      CobwebCrawler.new(:cache => 600, :valid_mime_types => 'text/*', :thread_count => 10).crawl(url) do |page|
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
    page = Nokogiri::HTML(RestClient.get(url))
    name = page.css("title")[0].text
    if name.blank?
      name = "Undefined"
    end
    return name
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
    if site_node = Site.find_by(url: url)
      words_hash.each do |word, frequency|
        word = word.downcase
        word_node = Word.find_by(word: word)
        added = false
        if word_node.nil? && word.length > 3 && word.length <= 15
          word_node = Word.create(word: word)
          AppearedIn.create(from_node: word_node, to_node: site_node, frequency: frequency)
        else
          word_node = Word.find_by(word: word)
        end
        if !word_node.nil?
          rel = word_node.query_as(:w).match("w-[rel:`appeared_in`]->(:Site {url: \"#{site_node.url}\"})").pluck(:rel).first
          if rel.nil?
            AppearedIn.create(from_node: word_node, to_node: site_node, frequency: frequency)
          else
            rel.add(frequency)
            rel.save
          end
        end
      end
    end
  end
end
