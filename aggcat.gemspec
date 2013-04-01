# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aggcat/version'

Gem::Specification.new do |spec|
  spec.name          = 'aggcat'
  spec.version       = Aggcat::VERSION
  spec.authors       = ['Gene Drabkin']
  spec.email         = ['gene.drabkin@gmail.com']
  spec.description   = %q{Aggcat wraps Intuit's Customer Account Data API in a simple client}
  spec.summary       = %q{Intuit Customer Account Data API client}
  spec.homepage      = 'https://github.com/cloocher/aggcat'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version     = '>= 1.9.2'
  spec.required_rubygems_version = '>= 1.3.6'

  spec.add_runtime_dependency 'oauth', '~> 0.4'
  spec.add_runtime_dependency 'nori', '~> 2.0'
  spec.add_runtime_dependency 'nokogiri', '~> 1.5'
  spec.add_runtime_dependency 'builder', '~> 3.2'
  spec.add_runtime_dependency 'active_support', '~> 3.0'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'bundler'
end
