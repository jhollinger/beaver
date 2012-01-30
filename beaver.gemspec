# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name = 'beaver'
  spec.version = '1.2.0'
  spec.summary = "Rails log parser"
  spec.description = "A simple DSL and command-line tool for discovering what people are up to in your Rails app"
  spec.authors = ['Jordan Hollinger']
  spec.date = '2011-12-08'
  spec.email = 'jordan@jordanhollinger.com'
  spec.homepage = 'http://github.com/jhollinger/beaver'

  spec.require_paths = ['lib']
  spec.files = [Dir.glob('lib/**/*'), 'README.rdoc', 'LICENSE'].flatten
  spec.executables << 'beaver'

  spec.specification_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION if spec.respond_to? :specification_version
end
