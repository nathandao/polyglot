Rails.application.routes.draw do
  post 'crawl' => 'crawler#index'
  get 'translate' => 'crawler#translate'
  mount Resque::Server, :at => '/resque'
end
