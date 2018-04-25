Rails.application.routes.draw do
  get 'notams/hello'
  
  get 'greetings/hello'

  get 'graph/graph'
  post 'graph/graph'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
