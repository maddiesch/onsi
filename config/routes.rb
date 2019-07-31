Onsi::Graph::Engine.routes.draw do
  METHODS = %i[get post patch delete].freeze

  match '/', to: 'graph/root#index', via: METHODS
  match '/:version/(*path)', to: 'graph/root#graph_action', via: METHODS
  match '/:version',         to: 'graph/root#graph_action', via: METHODS
end
