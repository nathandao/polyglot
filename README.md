Polyglot
===================

Basic web crawler that index all paragraphs of a site, return the list of top words used and their numbers of occurrences.

----------

Requirements:
-------------
The crawler and resque background jpb uses redis - so redis must be running on your machine

Install Redis with Homebrew and start redis-server:
<pre>
brew install redis
redis-server
</pre>

--------------

Setup Neo4j:
-------------

Install all required Gems from Gemfile:
<pre>
bundle install
</pre>

Install a preferred Neo4j version:
<pre>
rake neo4j:install[community-2.1.6]
</pre>

Change neo4j port to 7000 for development environment:
<pre>
rake neo4j:config[development,7000]
</pre>

Start neo4j
<pre>
rake neo4j:start
</pre>

Check if neo4j is running by going to.
<pre>
http://localhost:7000
</pre>

Start resque
---------
At this point, make sure redis-sever is running

Start resque workers:
<pre>
rake resque:work QUEUE='*'
</pre>

By default, neo4j is running at localhost:7474. To prevent possbile conflicts, the port for neo4j was changed to 7000.
Check these 2 lines in config/environments/development.rb:
<pre>
config.neo4j.session_type :server_db
config.neo4j.session_path = 'http://localhost:7000'
</pre>


Usage:
-------------
Start the rails server:
<pre>
rails s
</pre>

POST request to the site with parameter {url: "url of a site"} to
<pre>
http://localhost:3000/crawl
</pre>

Resque background job can be monitored at:
<pre>
http://localhost:3000/resque
</pre>

Possible responses:
--------------

Invalid URL:
<pre>
[{
  "error": true,
  "message": "invalid url",
  "data": NULL
}]
</pre>

Site was not indexed and was added to the crawl queue:
<pre>
[{
  "error": false,
  "message": "queued",
  "data": NULL
}]
</pre>

Site already indexed:
<pre>
[{
  "error": false,
  "message": "site indexed",
  "data": [
    [
      {
        "word": "apple",
        "frequency": 89,
      },
      {
        "word": "orange",
        "frequency": 65,
      },
      {
        "word": "wordpress",
        "frequency": 12,
      }
    ]
  ]
</pre>

Todo:
-------------
- Better algorithm to identify Words
- Http and devise authentication for /resque admin
- Site's "crawling in process" status
- Crawl queue status