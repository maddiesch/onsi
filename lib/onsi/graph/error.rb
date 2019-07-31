module Onsi
  module Graph
    class Error < StandardError
      ERROR_HEADERS = {
        'Content-Type' => 'application/json'
      }.freeze

      NODE_MODEL_NIL_ERROR = JSON.dump(
        errors: [
          {
            status: '404',
            code: 'not_found',
            detail: 'The requested resource could not be found.'
          }
        ]
      ).freeze

      NODE_MODEL_INVALID_TYPE = JSON.dump(
        errors: [
          {
            status: '500',
            code: 'internal_server_error',
            detail: 'Could not process request.'
          }
        ]
      ).freeze

      MODEL_UNKNOWN_VERSION = JSON.dump(
        errors: [
          {
            status: '404',
            code: 'not_found',
            detail: 'The requested verson does not exist.'
          }
        ]
      ).freeze

      MODEL_UNKNOWN_PATH = JSON.dump(
        errors: [
          {
            status: '404',
            code: 'not_found',
            detail: 'The requested resource could not be found.'
          }
        ]
      ).freeze

      MODEL_INVALID_TRANSVERSAL = JSON.dump(
        errors: [
          {
            status: '500',
            code: 'internal_server_error',
            detail: 'Internal server error'
          },
          {
            status: '404',
            code: 'not_found',
            detail: 'Requested resource not found due to invalid path'
          }
        ]
      ).freeze

      MODEL_PERMISSIONS_READ = JSON.dump(
        errors: [
          {
            status: '403',
            code: 'forbidden',
            detail: 'You do not have permission to view this resource.'
          }
        ]
      ).freeze

      MODEL_PERMISSIONS_CREATE = JSON.dump(
        errors: [
          {
            status: '403',
            code: 'forbidden',
            detail: 'You do not have permission to create this resource.'
          }
        ]
      ).freeze

      MODEL_PERMISSIONS_UPDATE = JSON.dump(
        errors: [
          {
            status: '403',
            code: 'forbidden',
            detail: 'You do not have permission to update this resource.'
          }
        ]
      ).freeze

      MODEL_PERMISSIONS_DESTROY = JSON.dump(
        errors: [
          {
            status: '403',
            code: 'forbidden',
            detail: 'You do not have permission to destroy this resource.'
          }
        ]
      ).freeze

      MODEL_MISSING_PATH_COMPONENT = JSON.dump(
        errors: [
          {
            status: '400',
            code: 'bad_request',
            detail: 'Invalid path components. Please check your URL and try again.'
          }
        ]
      ).freeze

      MODEL_INVALID_HTTP_METHOD = JSON.dump(
        errors: [
          {
            status: '400',
            code: 'bad_request',
            detail: 'Invalid HTTP method.'
          }
        ]
      ).freeze
    end

    class ConfigurationError < Error; end
  end
end
