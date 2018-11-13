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

  spec.add_dependency 'rails', '>= 5.0', '< 6.0'

  spec.add_development_dependency 'appraisal',        '~> 2.1.0'
  spec.add_development_dependency 'bundler',          '~> 1.16'
  spec.add_development_dependency 'database_cleaner', '~> 1.7.0'
  spec.add_development_dependency 'pry',              '~> 0.11.3'
  spec.add_development_dependency 'rake',             '~> 10.0'
  spec.add_development_dependency 'rspec-rails',      '~> 3.7.2'
  spec.add_development_dependency 'simplecov',        '~> 0.15'
  spec.add_development_dependency 'sqlite3',          '~> 1.3.10'
end
