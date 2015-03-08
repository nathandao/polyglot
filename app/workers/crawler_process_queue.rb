class CrawlerProcessQueue
  @queue = :crawler_process_queue

  def self.perform(url)
    user_agent = "PolyglotNinja"
    crawler = CobwebCrawler.new(:cache => 600,
                                :valid_mime_types => 'text/html',
                                :thread_count => 10)
    site_node = Site.find_by(url: url)
    if site_node.status == "pending"
      site_node.set_status("processing")
      crawler.crawl(url) do |page|
        if page[:mime_type] == 'text/html'
          site_node.add_indexed_page
          html = Nokogiri::HTML(page[:body])
          text = (html.xpath '//p/text()').to_s.scan(/[\p{Arabic}\p{Armenian}\p{Bengali}\p{Bopomofo}\p{Buhid}\p{Canadian_Aboriginal}\p{Devanagari}\p{Ethiopic}\p{Han}\p{Hangul}\p{Hanunoo}\p{Hiragana}\p{Katakana}\p{Khmer}\p{Lao}\p{Runic}\p{Tagbanwa}\p{Thai}\p{Tibetan}\p{Yi}]|\b[^\d ,.\/<>?;'\\:"\|\[\]\{\}§!@#$%%^&*()_+-=][\w{Common}\w{Braille}\w{Cherokee}\w{Cyrillic}\w{Georgian}\w{Greek}\w{Gujarati}\w{Gurmukhi}\w{Hebrew}\w{Inherited}\w{Kannada}\w{Latin}\w{Limbu}\w{Malayalam}\w{Mongolian}\w{Myanmar}\w{Ogham}\w{Oriya}\w{Sinhala}\w{Syriac}\w{Tagalog}\w{TaiLe}\w{Tamil}\w{Telugu}\w{Thaana}]+?\b/i)
          puts text
          words = Hash[
                          text.group_by(&:downcase).map{ |word,instances|
                            [word,instances.length] }.sort_by(&:last).reverse
                       ]
          words.each do |word, frequency|
            word = word.downcase
            word_node = Word.find_by(word: word)

            if word_node.nil? && word.length > 0
              word_node = Word.create(word: word)
              AppearedIn.create(from_node: word_node, to_node: site_node,
                                frequency: frequency)
            else
              word_node = Word.find_by(word: word)
            end

            if !word_node.nil?
              rel = word_node.get_site_rel(site_node)
              if rel.nil?
                AppearedIn.create(from_node: word_node, to_node: site_node,
                                  frequency: frequency)
              else
                rel.add(frequency)
                rel.save
              end
            end
          end
        end
      end
      site_node.set_status("indexed")
    end
  end
end