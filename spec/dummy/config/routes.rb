Rails.application.routes.draw do
  get 'api/v1/people' => 'people#index_v1'
  get 'api/v2/people' => 'people#index_v2'

  get 'api/v1/people/:person_id/emails'     => 'emails#index_v1'
  get 'api/v1/people/:person_id/emails/:id' => 'emails#show_v1'
  get 'api/v2/people/:person_id/emails/:id' => 'emails#show_v2'

  get 'api/v1/people/:person_id/emails/:email_id/messages' => 'messages#index_v1'
end
