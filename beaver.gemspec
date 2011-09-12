# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name = 'beaver'
  spec.version = '0.0.1.beta2'
  spec.summary = "Rails production log parser"
  spec.description = "A simple DSL for helping you discover what people are doing with your Rails app"
  spec.authors = ['Jordan Hollinger']
  spec.date = '2011-09-12'
  spec.email = 'jordan@jordanhollinger.com'
  spec.homepage = 'http://github.com/jhollinger/beaver'

  spec.require_paths = ['lib']
  spec.files = [Dir.glob('lib/**/*'), 'README.rdoc', 'LICENSE'].flatten
  spec.executables << 'beaver'

  spec.specification_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION if spec.respond_to? :specification_version
end
