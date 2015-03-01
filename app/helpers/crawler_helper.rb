module CrawlerHelper
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
end