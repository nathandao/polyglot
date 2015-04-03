Rails.application.routes.draw do
  post 'crawl' => 'crawler#index'
  get 'test' => 'crawler#test'
  get 'site' => 'translations#list_by_site'
  mount Resque::Server, :at => '/resque'
end
