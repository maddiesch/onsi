module Onsi
  ##
  # Used to include other objects in a root Resource objects.
  #
  # @example
  #   def index
  #     @person = Person.find(params[:person_id])
  #     @email = @person.emails.find(params[:id])
  #     @includes = Onsi::Includes.new(params[:include])
  #     @includes.fetch_person { @person }
  #     @includes.fetch_messages { @email.messages }
  #     render_resource(Onsi::Resource.new(@email, params[:version].to_sym, includes: @includes))
  #   end
  class Includes
    ##
    # The fetch method matcher regex
    #
    # @private
    FETCH_METHOD_REGEXP = Regexp.new('\Afetch_(?:.*)\z').freeze

    ##
    # The includes
    #
    # @return [Array<Symbol>]
    attr_reader :included

    ##
    # Create a new Includes object.
    #
    # @param included [String, Enumerable<String, Symbol>, nil] The keys to be
    #   included.
    #
    # @return [Onsi::Includes]
    def initialize(included)
      @included = parse_included(included)
    end

    ##
    # @private
    def method_missing(name, *args, &block)
      if FETCH_METHOD_REGEXP.match?(name)
        add_fetch_method(name.to_s.gsub(/\Afetch_/, ''), *args, &block)
      else
        super
      end
    end

    ##
    # @private
    def respond_to_missing?(name, include_private = false)
      if FETCH_METHOD_REGEXP.match?(name)
        true
      else
        super
      end
    end

    ##
    # Load all included resources.
    #
    # @private
    def load_included
      @load_included ||= {}.tap do |root|
        included.each do |name|
          fetcher = fetch_methods[name]
          next if fetcher.nil?

          results = fetcher.call
          root[name] = results
        end
      end
    end

    private

    def fetch_methods
      @fetch_methods ||= {}
    end

    def add_fetch_method(name, &block)
      if block.nil?
        raise ArgumentError, "Must specify a block for fetch_#{name}"
      end

      fetch_methods[name.to_sym] = block
    end

    def parse_included(included)
      case included
      when Enumerable
        included.map(&:to_sym)
      when String
        included.split(',').map(&:to_sym)
      when Symbol
        Array(included)
      when nil
        []
      else
        raise ArgumentError, "Onsi::Includes unknown included type #{included}"
      end
    end
  end
end
