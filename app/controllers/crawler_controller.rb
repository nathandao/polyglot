class CrawlerController < ApplicationController
  require 'rubygems'
  require 'bing_translator'
  respond_to :json

  def index
    error = true
    message = "invalid url"
    url = request.POST[:url]
    if !url.blank?
      url = "http://#{sanitize_url(url)}"
      if name = get_site_name(url)
        site = Site.find_by(url: url)
        if site.nil?
          Site.create(url: url, name: name)
          init_queue(url)
          error = false
          message = "queued"
        else
          message = "indexed"
          error = false
          words = site.most_used_words(500)
        end
      end
      render json: [ { error: error, message: message, data: words } ]
    end
  end

  def translate
    word = request.GET[:word]
    target_locale = request.GET[:target_locale]
    translator = BingTranslator.new(ENV['BING_CLIENT_ID'], ENV['BING_CLIENT_SECRET'])
    locale = translator.detect(word)
    translated = translator.translate(word, :from => locale, :to => target_locale)
    render json: [ { word: word, locale: locale, translated: translated,
                     target_locale: target_locale } ]
  end

  private

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

    def init_queue(url)
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
end