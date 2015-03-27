class PolyglotCrawlProcessJob
  @queue = :polyglot_crawl_process_job

  class << self

    def perform(content)
      content = HashUtil.deep_symbolize_keys(content)
      process(content)
    end

    private

      def process(content)
        url = content[:internal_urls][0][0..-3]
        if content[:mime_type] == 'text/html'
          words = get_words(content[:body])
          if words
            process_words(words, url)
          end
        end
      end


      def get_words(body_content)
        html = Nokogiri::HTML(body_content)
        text = split_words(html)
        words = text.group_by(&:downcase).map{ | word, instances |
            {:word => "#{word}", :frequency => instances.length} }
        if words.empty?
          return false
        end
        return words
      end


      def process_words(words, url)
        words.in_groups_of(50, false) {|w|
          data = {:words => w, :url => url}
          Resque.enqueue(WordProcessJob, data)
        }
        #site_node.add_indexed_page
      end


      def split_words(html)
        text = (html.xpath '//p/text()').to_s.scan(/[\p{Arabic}\p{Armenian}\p{Bengali}\p{Bopomofo}\p{Buhid}\p{Canadian_Aboriginal}\p{Devanagari}\p{Ethiopic}\p{Han}\p{Hangul}\p{Hanunoo}\p{Hiragana}\p{Katakana}\p{Khmer}\p{Lao}\p{Runic}\p{Tagbanwa}\p{Thai}\p{Tibetan}\p{Yi}]|\b[^\d ,.\/<>?;'\\:"\|\[\]\{\}§!@#$%^&*()_+-=\s][\w{Common}\w{Braille}\w{Cherokee}\w{Cyrillic}\w{Georgian}\w{Greek}\w{Gujarati}\w{Gurmukhi}\w{Hebrew}\w{Inherited}\w{Kannada}\w{Latin}\w{Limbu}\w{Malayalam}\w{Mongolian}\w{Myanmar}\w{Ogham}\w{Oriya}\w{Sinhala}\w{Syriac}\w{Tagalog}\w{TaiLe}\w{Tamil}\w{Telugu}\w{Thaana}]+?\b/i)
        return text
      end
    # end private
  end
end