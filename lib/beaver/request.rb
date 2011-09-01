module Beaver
  class Request
    BLANK_STR = ''
    BLANK_HASH = {}

    @types = []

    def self.<<(type)
      @types << type
    end

    def self.for(lines)
      @types.select { |t| t.match? lines }.first || BadRequest
    end

    def initialize(lines=nil)
      @lines = lines || ''
    end

    def to_s; @lines; end

    def good?; true; end
    def bad?; not good?; end

    def <<(line)
      @lines << line << $/
    end

    def path
      @path ||= parse_path
    end

    def method
      @method ||= parse_method
    end

    def status
      @status ||= parse_status
    end

    def params_str
      @params_str ||= parse_params_str
    end

    def params
      @params ||= parse_params
    end

    def ip
      @ip ||= parse_ip
    end

    # Returns true if the request has all the information it needs
    def completed?
      true
    end

    protected

    def parse_path
      BLANK_STR
    end

    def parse_method
      :method
    end

    def parse_status
      0
    end

    def parse_params_str
      BLANK_STR
    end

    def parse_params
      BLANK_HASH
    end

    def parse_ip
      BLANK_STR
    end
  end

  class BadRequest < Request
    def good?; false; end
  end
end
