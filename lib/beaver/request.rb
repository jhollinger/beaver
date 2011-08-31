module Beaver
  class Request
    attr_accessor :lines
    @types = []

    def self.<<(type)
      @types << type
    end

    def self.for(lines)
      @types.select { |t| t.match? lines }.first || self
    end

    def initialize(lines=nil)
      @lines = lines || ''
    end

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
end
