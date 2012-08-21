# -*- encoding: utf-8 -*-
require File.expand_path('../lib/graph-backend/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Thorben Schröder"]
  gem.email         = ["info@thorbenschroeder.de"]
  gem.description   = %q{A backend to store relations between entities.}
  gem.summary       = %q{A backend to store relations between entities.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "graph-backend"
  gem.require_paths = ["lib"]
  gem.version       = Graph::Backend::VERSION

  gem.add_dependency 'grape', '0.2.0'
  gem.add_dependency 'json', '1.7.4'
  gem.add_dependency 'neography', '0.0.29'
end
