class TranslationsController < ApplicationController
  respond_to :json


  def list_by_site
    url = request.GET[:url]

    if url.blank?
      render_response('error', 'missing url')
      return false
    end

    site = Site.new(url: url)
    site.sanitize_site_url()

    if site.is_valid?
      site = Site.find_by(url: site.url)

      if site.nil?
        render_response('error', 'site not found')
        return false
      end

      words = site.most_used_words(100)
      render_response('success', words)
      return true
    end

    render_response('error', 'invalid site')
  end


  private


    def render_response(result, data)
      render json: { error: result, data: data }
    end
  # End private
end
