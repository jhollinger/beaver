require 'rspec'

# Load Beaver
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib/'
require File.dirname(__FILE__) + '/../lib/beaver'

RSpec.configure do |c|
  c.mock_with :rspec
  c.expect_with(:rspec) { |c| c.syntax = :should }
end

RAILS_LOGS = File.dirname(__FILE__) + '/data/rails.log*'
HTTP_LOGS = File.dirname(__FILE__) + '/data/http.log*'

# Normalizes Time.new across Ruby 1.8 and 1.9. # Accepts the same arguments as Time.
class NormalizedTime < Time
  if RUBY_VERSION < '1.9'
    def self.new(*args)
      args.pop if args.last.is_a? String
      local(*args)
    end
  end
end
