require 'nokogiri'

class CrawlerController < ApplicationController

  def crawl
    # TODO: Replace with custom site_url parameter
    url = "guynathan.com"
    site = "https://#{url}"
    # TODO: Remove
    count = 0;

    if Site.find_by(url: url).blank?
      statistics = CobwebCrawler.new(:cache => 600, :redirect_limit => 5).crawl(site) do |page|
        html = Nokogiri::HTML(page[:body])
        text  = html.at('body').inner_text
        words_hash = get_word_frequencies(text.scan(/[a-z]+/i))
        puts words_hash
        process_words(words_hash, url)
      end
    else
      # Site already indexed!!!
      # TODO: List top words from database
    end
    puts "Finished Crawl with #{statistics[:page_count]} pages"
    #@words = Word.words
  end


  private

  def process_words(words_hash, url)
    words_hash.each do |word, frequency|
      word = word.downcase

      # TODO: Improve word validation logic
      if Word.find_by(word: word).blank? && word.length > 3 && word.length <= 10
        Word.create(word: word)
      end
    end
  end

  def get_word_frequencies(words)
    Hash[
      words.group_by(&:downcase).map{ |word,instances|
        [word,instances.length]
      }.sort_by(&:last).reverse
    ]
  end
end
