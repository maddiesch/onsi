Rails.application.routes.draw do
  scope 'api/:version' do
    get  '/people'                                      => 'people#index'
    get  '/people/:person_id/emails'                    => 'emails#index'
    get  '/people/:person_id/emails/:id'                => 'emails#show'
    get  '/people/:person_id/emails/:email_id/messages' => 'messages#index'
    post '/people/:person_id/emails/:email_id/messages' => 'messages#create'
    post '/people/:person_id/emails'                    => 'emails#create'
  end
end
