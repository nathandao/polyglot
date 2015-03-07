class CrawlerController < ApplicationController
  #TODO: remove response to :html
  respond_to :json

  def index
    error = true
    message = "invalid url"
    index = false
    url = request.POST[:url]
    if !url.blank?
      url = "http://#{sanitize_url(url)}"
      if name = get_site_name(url)
        site = Site.find_by(url: url)
        if site.nil?
          init_queue(url)
          error = false
          message = "queued"
        else
          message = "indexed"
          indexed = true
          words = site.most_used_words(100)
        end
      end
      render json: [ { error: error, message: message, data: words } ]
    end
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

    # Crawl related functions
    def init_queue(url)
      Resque.enqueue(CrawlerProcessQueue, url)
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
      # Otherwise, must be invalid address
      return false
    end
end