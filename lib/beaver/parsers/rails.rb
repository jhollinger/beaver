module Beaver
  module Parsers
    # This appears to work with Rails 3 logs
    class Rails < Request
      # Tell the Request class to use this parser to parse logs
      Request << self

      REGEX_METHOD = /^Started ([A-Z]+)/
      REGEX_METHOD_OVERRIDE = /"_method"=>"([A-Z]+)"/i
      REGEX_CONTROLLER = /Processing by (\w+Controller)#/
      REGEX_ACTION = /Processing by \w+Controller#(\w+) as/
      REGEX_COMPLETED = /^Completed (\d+)/
      REGEX_PATH = /^Started \w{3,4} "([^"]+)"/
      REGEX_PARAMS_STR = /^  Parameters: (\{.+\})$/
      REGEX_IP = /" for (\d+[\d.]+) at /
      REGEX_FORMAT = /Processing by .+ as (\w+)$/
      REGEX_MS = / in (\d+)ms/
      # Depending on the version of Rails, the time format may be wildly different
      REGEX_TIME = / at ([a-z0-9:\+\- ]+)$/i

      # Returns true if the given lines look like a Rails request
      def self.match?(lines)
        REGEX_METHOD =~ lines
      end

      # Returns true, always
      def valid?; true; end

      # Returns true if/when we have the final line of the multi-line Rails request
      def completed?
        REGEX_COMPLETED =~ @lines
      end

      protected

      # Parses and returns the request path
      def parse_path
        m = REGEX_PATH.match(@lines)
        m ? m.captures.first : BLANK_STR
      end

      # Parses and returns the request method
      def parse_method
        m = REGEX_METHOD_OVERRIDE.match(@lines)
        m = REGEX_METHOD.match(@lines) if m.nil?
        m ? m.captures.first.downcase.to_sym : :unknown
      end

      # Parses the name of the Rails controller which handled the request
      def parse_controller
        c = REGEX_CONTROLLER.match(@lines) if c.nil?
        c ? c.captures.first : BLANK_STR
      end

      # Parses the name of the Rails controller action which handled the request
      def parse_action
        a = REGEX_ACTION.match(@lines) if a.nil?
        a ? a.captures.first.to_sym : :unknown
      end

      # Parses and returns the response status
      def parse_status
        m = REGEX_COMPLETED.match(@lines)
        m ? m.captures.first.to_i : 0
      end

      # Parses and returns the request parameters as a String
      def parse_params_str
        m = REGEX_PARAMS_STR.match(@lines)
        m ? m.captures.first : BLANK_STR
      end

      # Parses and returns the request parameters as a Hash (relatively expensive)
      def parse_params
        p = params_str
        p.empty? ? BLANK_HASH : Utils.str_to_hash(p)
      end

      # Parses and returns the request's IP address
      def parse_ip
        m = REGEX_IP.match(@lines)
        m ? m.captures.first : BLANK_STR
      end

      # Parses and returns the respones format
      def parse_format
        m = REGEX_FORMAT.match(@lines)
        m ? m.captures.first.to_s.downcase.to_sym : :unknown
      end

      # Parses and returns the number of milliseconds it took for the request to complete
      def parse_ms
        m = REGEX_MS.match(@lines)
        m ? m.captures.first.to_i : 0
      end

      # Parses and returns the time at which the request was made
      def parse_time
        m = REGEX_TIME.match(@lines)
        m ? Time.parse(m.captures.first) : nil
      end
    end
  end
end
