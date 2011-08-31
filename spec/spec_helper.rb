require 'rspec'

# Load Beaver
require File.dirname(__FILE__) + '/../lib/beaver/beaver'
require File.dirname(__FILE__) + '/../lib/beaver/dam'
require File.dirname(__FILE__) + '/../lib/beaver/request'
require File.dirname(__FILE__) + '/../lib/beaver/parsers/rails'

Rspec.configure do |c|
  c.mock_with :rspec
end

LOG_FILES = File.dirname(__FILE__) + '/data/production.log*'
