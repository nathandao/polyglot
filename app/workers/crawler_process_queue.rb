class CrawlerProcessQueue
  @queue = :crawler_process_queue

  def self.perform(url)
    user_agent = "PolyglotNinja"
    crawler = CobwebCrawler.new(:cache => 600,
                                :valid_mime_types => 'text/html',
                                :thread_count => 10)
    if site_node = Site.create(url: url, name: name)
      crawler.crawl(url) do |page|
        if page[:mime_type] == 'text/html'
          html = Nokogiri::HTML(page[:body])
          text = (html.xpath '//p/text()').to_s.scan(/[a-z]+/i)
          words_hash = Hash[
                          text.group_by(&:downcase).map{ |word,instances|
                            [word,instances.length] }.sort_by(&:last).reverse
                       ]
          words_hash.each do |word, frequency|
            word = word.downcase
            word_node = Word.find_by(word: word)

            if word_node.nil? && word.length > 3 && word.length <= 15
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
    end
  end
end