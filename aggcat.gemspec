# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aggcat/version'

Gem::Specification.new do |spec|
  spec.name          = 'aggcat'
  spec.version       = Aggcat::VERSION
  spec.authors       = ['Gene Drabkin']
  spec.email         = ['gene.drabkin@gmail.com']
  spec.description   = %q{Intuit Customer Account Data API client}
  spec.summary       = %q{Intuit Customer Account Data API client}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'oauth', '~> 0.4'
  spec.add_development_dependency 'nori', '~> 2.0'
  spec.add_development_dependency 'nokogiri', '~> 1.5'
  spec.add_development_dependency 'active_support', '~> 3.0'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

end
