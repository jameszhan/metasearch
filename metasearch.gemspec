# -*- encoding: utf-8 -*-
require File.expand_path('../lib/metasearch/version', __FILE__)

Gem::Specification.new do |spec|
  spec.authors       = ["James Zhan"]
  spec.email         = ["zhiqiangzhan@gmail.com"]
  spec.description   = %q{Meta Search Engine for crawl specific content}
  spec.summary       = %q{You can just the DSL to crawl the content you mentioned.}
  spec.homepage      = "https://github.com/jameszhan/metasearch"

  spec.files         = `git ls-files`.split($\)
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.name          = "metasearch"
  spec.require_paths = ["lib"]
  spec.version       = Metasearch::VERSION

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'

	spec.add_dependency 'anemone', '>=0'
end


