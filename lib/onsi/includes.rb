module Onsi
  class Includes
    attr_reader :included

    def initialize(included)
      @included = parse_included(included)
    end

    def method_missing(name, *args, &block)
      if name =~ /\Afetch_(.*)/
        add_fetch_method(name.to_s.gsub(/\Afetch_/, ''), *args, &block)
      else
        super
      end
    end

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
