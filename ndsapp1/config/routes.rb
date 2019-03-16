Rails.application.routes.draw do
#  get 'notams/hello'
#  get 'greetings/hello'

  get 'graph/graph'
  post 'graph/graph'
  get 'graph/scenario'
  post 'graph/scenario'
  get 'graph/prod'
  post 'graph/prod'
  get 'graph/fntb'
  post 'graph/fntb'
  get 'graph/fntb_test'
  post 'graph/fntb_test'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
