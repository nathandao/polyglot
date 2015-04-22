# Polyglot

Basic web crawler that index all paragraphs of a site, return the list of top words used and their numbers of occurrences.

## Requirements

The crawler and resque background jpb uses redis - so redis must be running on your machine

Install Redis with Homebrew and start redis-server:

    brew install redis
    redis-server

## Setup Neo4j:

Install all required Gems from Gemfile:

    bundle install

Install a preferred Neo4j version:

    rake neo4j:install[community-2.2.0]

If you want to use neo4j enterprise version, copy your download version into the db/neo4j/development folder

Change neo4j port to 7000 for development environment:

    rake neo4j:config[development,7000]

Optional: enable authentication for Neo4j:

    rake neo4j:config[development,7000]


If you want to use authentication for Neo4j:

    rake neo4j:enable_auth


Start neo4j

    rake neo4j:start


Check if neo4j is running by going to. ```http://localhost:7000```


## Start resque

At this point, make sure redis-sever is running

Start resque workers:

    rake resque:workers QUEUE='*' COUNT=10
    rake resque:workers QUEUE=word_crawl_job COUNT=5

By default, neo4j is running at localhost:7474. To prevent possbile conflicts, the port for neo4j was changed to 7000.
Check these 2 lines in config/environments/development.rb:

    config.neo4j.session_type :server_db
    config.neo4j.session_path = 'http://localhost:7000'

## Usage:

Start the rails server:

    rails s

POST request to the site with parameter {url: "url of a site"} to 'http://localhost:3000/crawl'

    curl -H "Content-Type: application/json" -d '{"url":"wired.com"}' http://localhost:3000/crawl

Resque background job can be monitored at:

    http://localhost:3000/resque


## Possible responses:

Invalid URL:

    [{
      "error": true,
      "message": "invalid url",
      "data": NULL
    }]

Site was not indexed and was added to the crawl queue:

    [{
      "error": false,
      "message": "queued",
      "data": NULL
    }]

Site already indexed:

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
