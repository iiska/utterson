# -*- coding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'utterson'
  s.version     = '0.1.1'
  s.summary     = "Friendly HTML crawler and url checker"
  s.description = "Traverses all HTML files from given directory and checks links found in them."
  s.authors     = ["Juhamatti Niemelä"]
  s.email       = 'iiska@iki.fi'
  s.homepage    = 'https://github.com/iiska/utterson'
  s.license     = 'MIT'

  s.files = Dir['bin/*'] + Dir['lib/**/*.rb'] + %w(README.md)
  s.bindir = 'bin'
  s.executables << 'utterson'

  s.test_files = Dir['spec/**/*']

  s.required_ruby_version = "~> 1.9.3"
  s.add_runtime_dependency 'trollop'
  s.add_runtime_dependency 'nokogiri'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'webmock', '~> 1.15.2'
end
