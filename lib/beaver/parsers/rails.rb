module Beaver
  module Parsers
    class Rails < Request
      Request << self

      REGEX_METHOD = /^Started ([A-Z]+)/
      REGEX_METHOD_OVERRIDE = /"_method"=>"([A-Z]+)"/i
      REGEX_COMPLETED = /^Completed (\d+)/
      REGEX_PATH = /^Started \w{3,4} "([^"]+)"/
      REGEX_PARAMS_STR = /^  Parameters: ({.+})$/
      REGEX_IP = /" for (\d+[\d.]+) at /

      def self.match?(lines)
        REGEX_METHOD =~ lines
      end

      def valid?; true; end

      def completed?
        REGEX_COMPLETED =~ lines
      end

      protected

      def parse_path
        m = REGEX_PATH.match(@lines)
        m ? m.captures.first : BLANK_STR
      end

      def parse_method
        m = REGEX_METHOD_OVERRIDE.match(@lines)
        m = REGEX_METHOD.match(@lines) if m.nil?
        m ? m.captures.first.downcase.to_sym : :method
      end

      def parse_status
        m = REGEX_COMPLETED.match(@lines)
        m ? m.captures.first.to_i : 0
      end

      def parse_params_str
        m = REGEX_PARAMS_STR.match(@lines)
        m ? m.captures.first : BLANK_STR
      end

      def parse_params
        p = params_str
        p.empty? ? BLANK_HASH : Utils.str_to_hash(p)
      end

      def parse_ip
        m = REGEX_IP.match(@lines)
        m ? m.captures.first : BLANK_STR
      end
    end
  end
end
