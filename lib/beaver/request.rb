module Beaver
  # Represents a single request from the logs.
  class Request
    BLANK_STR = ''
    BLANK_HASH = {}

    # Holds the Parser classes used to parser requests
    @types = []

    # Add a child Request parser.
    def self.<<(type)
      @types << type
    end

    # Returns the correct Request parser class for the given log lines. If one cannot be found,
    # the BadRequest class is returned, which the caller will want to ignore.
    def self.for(lines)
      @types.select { |t| t.match? lines }.first || BadRequest
    end

    # Accepts a String of log lines, presumably ones which belong to a single request.
    def initialize(lines=nil)
      @lines = lines || ''
      @final = false
    end

    # Returns the log lines that make up this Request.
    def to_s; @lines; end

    # Returns true if this is a "good" request.
    def good?; true; end
    # Returns true if this is a "bad" request.
    def bad?; not good?; end

    # Append a log line
    def <<(line)
      @lines << line << $/
    end

    # Returns the request path
    def path
      @path ||= parse_path
    end

    # Returns the request method
    def method
      @method ||= parse_method
    end

    # Returns the response status
    def status
      @status ||= parse_status
    end

    # Returns the request parameters as a String
    def params_str
      @params_str ||= parse_params_str
    end

    # Returns the request parameters as a Hash (this is more expensive than Request#params_str)
    def params
      @params ||= parse_params
    end

    # Returns the IP address of the request
    def ip
      @ip ||= parse_ip
    end

    # Returns the number of milliseconds it took for the request to complete
    def ms
      @ms ||= parse_ms
    end

    # When called inside of a Beaver::Dam#hit block, this Request will *not* be matched.
    def skip!
      throw :skip
    end

    # When called inside of a Beaver::Dam#hit block, this Request will not match against any other Beaver::Dam.
    def final!
      @final = true
    end

    # Returns true if this Request should not be matched against any more Dams.
    def final?
      @final
    end

    # Returns true if the request has all the information it needs to be properly parsed
    def completed?
      true
    end

    protected

    # Parses and returns the request path
    def parse_path
      BLANK_STR
    end

    # Parses and returns the request method
    def parse_method
      :method
    end

    # Parses and returns the response status
    def parse_status
      0
    end

    # Parses and returns the request params as a String
    def parse_params_str
      BLANK_STR
    end

    # Parses and returns the request params as a Hash
    def parse_params
      BLANK_HASH
    end

    # Parses and returns the request IP address
    def parse_ip
      BLANK_STR
    end

    # Parses and returns the number of milliseconds it took for the request to complete
    def parse_ms
      0
    end
  end

  # Represents a BadRequest that no parser could figure out.
  class BadRequest < Request
    # Returns false, always
    def good?; false; end
  end
end
