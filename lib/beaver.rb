begin
  require 'zlib'
rescue LoadError
  $stderr.puts "Zlib not available; compressed log files will be skipped."
end

require 'beaver/utils'
require 'beaver/beaver'
require 'beaver/dam'
require 'beaver/request'

require 'beaver/parsers/rails'
require 'beaver/parsers/http'
