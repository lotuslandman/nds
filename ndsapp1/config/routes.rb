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
  get 'graph/left_half'
  post 'graph/left_half'
  get 'graph/right_half'
  post 'graph/right_half'
#  get 'graph/expand_left'
#  post 'graph/expand_left'
#  get 'graph/expand_right'
#  post 'graph/expand_right'

  get 'graph/response_time'
  post 'graph/response_time'
  get 'graph/number_of_notams'
  post 'graph/number_of_notams'
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
