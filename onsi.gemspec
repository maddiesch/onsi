lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'onsi/version'

Gem::Specification.new do |spec|
  spec.name          = 'onsi'
  spec.version       = Onsi::VERSION
  spec.authors       = ['Maddie Schipper']
  spec.email         = ['me@maddiesch.com']

  spec.summary       = 'Format JSON API Responses'
  spec.description   = 'Format JSON API responses and parse inbound requests.'
  spec.homepage      = 'https://github.com/maddiesch/onsi'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency 'addressable', '>= 2.5', '< 3.0'
  spec.add_dependency 'rails',       '>= 5.0', '< 7.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'simplecov', '< 0.18' # >= .18 breaks the test reporter
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'yard'
end
