class CrawlerController < ApplicationController

  def crawl
    url = "guynathan.com"
    site = "https://#{url}"
    count = 0;

    if Site.find_by(url: url).blank?
      statistics = CobwebCrawler.new(:cache => 600, :follow_redirects => false).crawl(site) do |page|
        page_words = ActionController::Base.helpers.strip_tags(page[:body]).split(/\W+/)
        process_words(page_words, url)
        count = count + 1
        break if count > 1
      end
    else
      # Site already indexed!!!
    end

    @words = Word.words
  end

  private

  def process_words(page_words, site_url)
    page_words.each do |word|
      word = word.downcase

      if Word.find_by(word: word).blank? && word.length > 2 && word.length <= 15
        Word.create(word: word)
      end
    end
  end
end
