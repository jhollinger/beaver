# encoding: utf-8
require File.join(File.dirname(__FILE__), 'lib', 'beaver', 'version')

Gem::Specification.new do |spec|
  spec.name = 'beaver'
  spec.version = Beaver::VERSION
  spec.summary = "Rails log parser"
  spec.description = "A simple DSL and command-line tool for discovering what people are up to in your Rails app"
  spec.authors = ['Jordan Hollinger']
  spec.date = '2014-01-28'
  spec.email = 'jordan@jordanhollinger.com'
  spec.homepage = 'http://github.com/jhollinger/beaver'

  spec.require_paths = ['lib']
  spec.files = [Dir.glob('lib/**/*'), 'README.rdoc', 'LICENSE'].flatten
  spec.executables << 'beaver'

  spec.specification_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION if spec.respond_to? :specification_version
end
