module Beaver
  class Request
    attr_accessor :lines
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
      ''
    end

    def parse_method
      :method
    end

    def parse_status
      0
    end

    def parse_params
      {}
    end

    def parse_ip
      ''
    end
  end

  class BadRequest < Request
    def good?; false; end
  end
end
