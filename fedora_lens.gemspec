# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fedora_lens/version'

Gem::Specification.new do |spec|
  spec.name          = "fedora_lens"
  spec.version       = FedoraLens::VERSION
  spec.authors       = ["Justin Coyne", "Brian Maddy"]
  spec.email         = ["justin@curationexperts.com"]
  spec.summary       = %q{A client for Fedora Commons Repository (fcrepo) version 4}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "APACHE2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "childprocess"

  spec.add_dependency 'rdf-turtle', '~> 1.1.2'
  spec.add_dependency 'activemodel', '~> 4.0.2'
  spec.add_dependency 'nokogiri', '~> 1.6.1'
  spec.add_dependency 'ldp'
end
