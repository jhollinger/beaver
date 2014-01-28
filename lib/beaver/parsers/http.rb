module Beaver
  module Parsers
    # Parser for HTTP Common Log entries. See the Request class for more log entry attributes.
    class HTTP < Request
      # The Combined Log Format
      FORMAT = '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"' # :nodoc:
      # The Combined Log Format as an array of symbols
      FORMAT_SYMBOLS = FORMAT.split(' ').map(&:to_sym) # :nodoc:
      FHOST, FID, FUSER, FTIME, FREQUEST, FSTATUS, FSIZE, FREFERER, FUA = FORMAT_SYMBOLS # :nodoc:
      REGEX_TIME_FIX = /([0-9]{4}):([0-9]{2})/

      # Regex matchers keyed by opening quotes, etc.
      MATCHERS = {'[' => /^\[([^\]]+)\] ?/, '"' => /^"([^"]+)" ?/} # :nodoc:
      MATCHERS.default = /^([^ ]+) ?/

      # Matches an HTTP Log entry
      REGEX_MATCH = %r{\[[0-9]{2}/\w+/[0-9:]+ } # :nodoc:
      # Matches the request method, url and params
      REGEX_REQUEST = /^([A-Z]+) (\/[^\?]+)\??(.*) HTTP\/1/ # :nodoc:
      # Matches the request date
      REGEX_DATE = %r{^([0-9]{2}/[a-z]+/[0-9]+)}i # :nodoc:

      # Partially parse the request
      def initialize(data)
        super
        pre_parse!
      end

      # Returns the HTTP method as a symbol
      def method
        parse_request! if @method.nil?
        @method
      end

      # Returns the request path
      def path
        parse_request! if @path.nil?
        @path
      end

      # Parses and returns the request parameters as a Hash
      def parse_params
        params_str.empty? ? BLANK_HASH : CGI::parse(params_str).inject({}) do |hash, (param, value)|
          hash[param] = if value.is_a?(Array) and value.size == 1 and param !~ /\[\d*\]$/
            value[0]
          else
            value
          end
          hash
        end
      end

      # Returns the url query string
      def params_str
        parse_request! if @params_str.nil?
        @params_str
      end

      # Returns the response size (in bytes)
      def size
        @size ||= @request[FSIZE].to_i
      end

      # Returns the REFERER [sic]
      def referer
        @request[FREFERER]
      end
      alias_method :referrer, :referer

      # Returns the user agent string
      def user_agent
        @request[FUA]
      end

      protected

      # Parse and cache the request method, URL and any params
      def parse_request!
        REGEX_REQUEST.match(@request[FREQUEST])
        @method = $1 ? $1.downcase.to_sym : :unknown
        @path = $2 || BLANK_STR
        @params_str = $3 || BLANK_STR
      end

      # Parses and returns the response status
      def parse_status
        @request[FSTATUS].to_i
      end

      # Parses and returns the request's IP address
      def parse_ip
        @request[FHOST] || BLANK_STR
      end

      # Parses and returns the time at which the request was made
      def parse_date
        REGEX_DATE.match(@request[FTIME]) ? Date.parse($1) : nil
      end

      # Parses and returns the time at which the request was made
      def parse_time
        time_str = @request[FTIME].sub(REGEX_TIME_FIX) { "#{$1} #{$2}" }
        Time.parse(time_str) rescue nil
      end

      private

      # Break the log line down into sections, store them in @request as a Hash.
      # Each section may be further parsed on-demand.
      # XXX This is probably really slow
      def pre_parse!
        line = @data.clone
        request = {}
        for f in FORMAT_SYMBOLS
          line.slice!(MATCHERS[line[0,1]])
          request[f] = $1
        end
        @request = request
      end
    end
  end
end
