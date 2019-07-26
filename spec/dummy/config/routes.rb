Rails.application.routes.draw do
  scope 'api/:version' do
    get  '/people'                                      => 'people#index'
    post '/people'                                      => 'people#create'
    get  '/people/:person_id/emails'                    => 'emails#index'
    get  '/people/:person_id/emails/:id'                => 'emails#show'
    get  '/people/:person_id/emails/:email_id/messages' => 'messages#index'
    post '/people/:person_id/emails/:email_id/messages' => 'messages#create'
    post '/people/:person_id/emails'                    => 'emails#create'
    get  '/people/:person_id/contacts'                  => 'contacts#index'

    match '(*path)' => 'application#cors_options', via: :options
  end
end
