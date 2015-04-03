Rails.application.routes.draw do
  post 'crawl' => 'crawler#index'
  get 'test' => 'crawler#test'
  mount Resque::Server, :at => '/resque'
end
