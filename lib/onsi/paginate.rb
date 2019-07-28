require_relative 'errors'

module Onsi
  ##
  # Pagination handles cursor pagination.
  #
  # It handles setting up a cursor and ordering the query. The next cursor will be added to the
  # response's meta object.
  #
  # @example Controller Action
  # def index
  #   render_resource(Onsi::Paginate.perform(person.messages, 'messages', params))
  # end
  #
  # @author Maddie Schipper
  # @since 1.4.0
  class Paginate
    Result = Struct.new(:query, :params)

    class << self
      ##
      # Modify the query based on the pagination options
      #
      # @param query [#reorder, #limit, #where, #last] The query to modify
      #
      # @param type [#to_s] The type of the pagination. This us used to verify the cursor
      #
      # @param params [#fetch] The request params.
      #
      # @return [Onsi::Paginate::Result]
      def perform(query, type, params, options = {})
        cursor_type = type.to_s
        cursor_param = options.fetch(:cursor_param, :cursor)
        max_per_page = options.fetch(:max_per_page, 100)
        per_page_param = options.fetch(:per_page_param, :per_page)

        # rubocop:disable Lint/ShadowingOuterLocalVariable
        cursor_generator = options.fetch(:cursor, ->(query, type) { Paginate.cursor_for_query(query, type) })
        cursor_offset = options.fetch(:offset, ->(query, type, cursor) { Paginate.cursor_offset(query, type, cursor) })
        # rubocop:enable Lint/ShadowingOuterLocalVariable

        order_by = options.fetch(:order_by, id: :asc)

        per_page = params.fetch(per_page_param, 25).to_i
        raise Onsi::Errors::PaginationError, "too many objects per page, max #{max_per_page}" if per_page > max_per_page

        query = query.reorder(order_by)
        query = query.limit(per_page)
        query = cursor_offset.call(query, cursor_type, params.fetch(cursor_param)) if params.fetch(cursor_param, nil).present?

        response_params = {}.tap do |rp|
          rp[per_page_param] = per_page
          value = cursor_generator.call(query, cursor_type)
          rp[cursor_param] = value unless value.nil?
        end

        Result.new(query, response_params)
      end

      ##
      # @private
      def cursor_for_query(query, type)
        obj = query.last

        return nil if obj.nil?

        Base64.strict_encode64([
          type.to_s,
          obj.id.to_s
        ].join(':'))
      end

      ##
      # @private
      def cursor_offset(query, cursor_type, cursor)
        type, id = Base64.strict_decode64(cursor).split(':', 2)
        raise Onsi::Errors::PaginationError, 'invalid cursor type' unless cursor_type.to_s == type

        query.where(id: (id.to_i + 1)...Float::INFINITY)
      rescue ArgumentError => e
        raise e if e.message.downcase != 'invalid base64'

        raise Onsi::Errors::PaginationError, 'invalid cursor format'
      end
    end
  end
end
