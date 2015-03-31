class CrawlerController < ApplicationController
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
        name = "Undefined" if name.blank?
        return name
      end
    rescue Exception
      return false
    end

  # End private

end