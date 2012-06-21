module Beaver
  module Parsers
    # This appears to work with Rails 3 logs
    class Rails < Request
      # Tell the Request class to use this parser to parse logs
      Request << self

      REGEX_MATCH = /^Started [A-Z]+/
      REGEX_METHOD = /^Started ([A-Z]+)/
      REGEX_METHOD_OVERRIDE = /"_method"=>"([A-Z]+)"/i
      REGEX_CONTROLLER = /Processing by (\w+Controller)#/
      REGEX_ACTION = /Processing by \w+Controller#(\w+) as/
      REGEX_COMPLETED = /Completed (\d+)/
      REGEX_PATH = /^Started \w{3,4} "([^"]+)"/
      REGEX_PARAMS_STR = /  Parameters: (\{.+\})$/
      REGEX_IP = /" for (\d+[\d.]+) at /
      REGEX_FORMAT = /Processing by .+ as (\w+)$/
      REGEX_MS = / in (\d+)ms/
      REGEX_TAGS = /^(\[.+\] )+/
      REGEX_TAG = /\[([^\]]+)\] /
      # Depending on the version of Rails, the time format may be wildly different
      REGEX_TIME = / at ([a-z0-9:\+\- ]+)$/i

      # Returns true if/when we have the final line of the multi-line Rails request
      def completed?
        REGEX_COMPLETED =~ @data
      end

      # Returns the class name of the Rails controller that handled the request
      def controller
        @controller ||= REGEX_CONTROLLER.match(@data) ? $1 : BLANK_STR
      end

      # Returns the class name of the Rails controller action that handled the request
      def action
        @action ||= REGEX_ACTION.match(@data) ? $1.to_sym : :unknown
      end

      # Returns the responses format (html, json, etc)
      def format
        @format ||= REGEX_FORMAT.match(@data) ? $1.downcase.to_sym : :unknown
      end

      # Returns the number of milliseconds it took for the request to complete
      def ms
        @ms ||= REGEX_MS.match(@data) ? $1.to_i : 0
      end

      # Returns the request parameters as a Hash (this is more expensive than Request#params_str)
      def params
        @params ||= params_str.empty? ? BLANK_HASH : Utils.str_to_hash(params_str)
      end

      # Returns the tags string associated with the request (e.g. "[tag1] [tag2] ")
      def tags_str
        @tags_str ||= REGEX_TAGS.match(@data) ? $1 : nil
      end

      # Returns an array of tags associated with the request
      def tags
        @tags ||= if t = tags_str
          tags = t.scan(REGEX_TAG)
          tags.flatten!
          tags.uniq!
          tags.map! &:downcase
          tags
        else
          []
        end
      end

      protected

      # Parses and returns the request path
      def parse_path
        REGEX_PATH.match(@data) ? $1 : BLANK_STR
      end

      # Parses and returns the request method
      def parse_method
        m = REGEX_METHOD_OVERRIDE.match(@data)
        m = REGEX_METHOD.match(@data) if m.nil?
        m ? m.captures.first.downcase.to_sym : :unknown
      end

      # Parses and returns the response status
      def parse_status
        REGEX_COMPLETED.match(@data) ? $1.to_i : 0
      end

      # Parses and returns the request parameters as a String
      def parse_params_str
        REGEX_PARAMS_STR.match(@data) ? $1 : BLANK_STR
      end

      # Parses and returns the request's IP address
      def parse_ip
        REGEX_IP.match(@data) ? $1 : BLANK_STR
      end

      # Parses and returns the time at which the request was made
      def parse_date
        REGEX_TIME.match(@data) ? Date.parse($1) : nil
      end

      # Parses and returns the time at which the request was made
      def parse_time
        REGEX_TIME.match(@data) ? Time.parse($1) : nil
      end
    end
  end
end
