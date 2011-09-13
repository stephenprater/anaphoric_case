# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "anaphoric_case/version"

Gem::Specification.new do |s|
  s.name        = "anaphoric_case"
  s.version     = AnaphoricCase::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Prater"]
  s.email       = ["me@stephenprater.com"]
  s.homepage    = "http://github.com/stephenprater/anaphoric_case"
  s.summary     = %q{Provides a simple anaphoric case statement (called "switch/on")}
  s.description = %q{You have twenty or so methods, and you want to call the first one that returns something other than nil,
  If the dog is on fire, put it out.}

  s.rubyforge_project = "anaphoric_case"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]


  s.add_development_dependency('rspec')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('rspec-prof')
  s.add_development_dependency('i18n')
end
