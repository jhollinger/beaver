module Beaver
  # A Dam "traps" certain Requests, using one or more matching options. A request must meet *all* of the 
  # matching options specified.
  # 
  # Matchers:
  #
  #  :path => String for exact match, or Regex
  #
  #  :method => A Symbol of :get, :post, :put or :delete, or any array of any (reads the magic _method field if present)
  #
  #  :status => A Fixnum like 404 or a Range like (500..503)
  # 
  #  :ip => String for exact match, or Regex
  #
  #  :format => A symbol or array of symbols of response formats like :html, :json
  # 
  #  :longer_than => Fixnum n. Matches any request which took longer than n milliseconds to complete.
  # 
  #  :shorter_than => Fixnum n. Matches any request which took less than n milliseconds to complete.
  # 
  #  :before => Date or Time for which the request must have ocurred before
  # 
  #  :after => Date or Time for which the request must have ocurred after
  # 
  #  :on => Date - the request must have ocurred on this date
  # 
  #  :params_str => A regular expressing matching the Parameters string
  # 
  #  :params => A Hash of Symbol=>String/Regexp pairs: {:username => 'bob', :email => /@gmail\.com$/}. All must match.
  #
  #  :match => A "catch-all" Regex that will be matched against the entire request string
  # 
  # The last argument may be a block, which will be called everytime this Dam is hit.
  # The block will be run in the context of the Request object. This can be used for 
  # further checks or for reporting purposes.
  class Dam
    # The symbol name of this Beaver::Dam
    attr_reader :name
    # An optional callback when a Beaver::Request hits this Dam
    attr_reader :callback
    # An array of Beaver::Request objects that have hit this Dam
    attr_reader :hits

    # Name should be a unique symbol. Matchers is an options Hash. The callback will be evauluated within
    # the context of a Beaver::Request.
    def initialize(name, matchers, &callback)
      @name = name
      @callback = callback
      @hits = []
      set_matchers(matchers)
    end

    # Returns an array of IP address that hit this Dam.
    def ips
      @ips ||= @hits.map(&:ip).uniq
    end

    # Returns true if the given Request hits this Dam, false if not.
    def matches?(request)
      return false if request.final?
      return false unless @match_path_s.nil? or @match_path_s == request.path
      return false unless @match_path_r.nil? or @match_path_r =~ request.path
      return false unless @match_longer.nil? or @match_longer < request.ms
      return false unless @match_shorter.nil? or @match_shorter > request.ms
      return false unless @match_method_s.nil? or @match_method_s == request.method
      return false unless @match_method_a.nil? or @match_method_a.include? request.method
      return false unless @match_status.nil? or @match_status === request.status
      return false unless @match_ip_s.nil? or @match_ip_s == request.ip
      return false unless @match_ip_r.nil? or @match_ip_r =~ request.ip
      return false unless @match_format_s.nil? or @match_format_s == request.format
      return false unless @match_format_a.nil? or @match_format_a.include? request.format
      return false unless @match_before.nil? or @match_before > request.time
      return false unless @match_after.nil? or @match_after < request.time
      return false unless @match_on.nil? or (@match_on.year == request.time.year and @match_on.month == request.time.month and @match_on.day == request.time.day)
      return false unless @match_params_str.nil? or @match_params_str =~ request.params_str
      return false unless @match_r.nil? or @match_r =~ request.to_s
      return false unless @match_params.nil? or matching_hashes?(@match_params, request.params)
      return true
    end

    private

    # Recursively compares to Hashes. If all of Hash A is in Hash B, they match.
    def matching_hashes?(a,b)
      intersecting_keys = a.keys & b.keys
      if intersecting_keys.any?
        a_values = a.values_at(*intersecting_keys)
        b_values = b.values_at(*intersecting_keys)
        indicies = (0..b_values.size-1)
        indicies.all? do |i|
          if a_values[i].is_a? String
            a_values[i] == b_values[i]
          elsif a_values[i].is_a?(Regexp) and b_values[i].is_a?(String)
            a_values[i] =~ b_values[i]
          elsif a_values[i].is_a?(Hash) and b_values[i].is_a?(Hash)
            matching_hashes? a_values[i], b_values[i]
          else
            false
          end
        end
      else
        false
      end
    end

    # Parses and checks the validity of the matching options passed to the Dam.
    def set_matchers(matchers)
      case matchers[:path].class.name
        when String.name then @match_path_s = matchers[:path]
        when Regexp.name then @match_path_r = matchers[:path]
        else raise ArgumentError, "Path must be a String or a Regexp (it's a #{matchers[:path].class.name})"
      end if matchers[:path]

      case matchers[:method].class.name
        when Symbol.name then @match_method_s = matchers[:method].to_s.downcase.to_sym
        when Array.name then @match_method_a = matchers[:method].map { |m| m.to_s.downcase.to_sym }
        else raise ArgumentError, "Method must be a Symbol or an Array (it's a #{matchers[:method].class.name})"
      end if matchers[:method]

      case matchers[:status].class.name
        when Fixnum.name, Range.name then @match_status = matchers[:status]
        else raise ArgumentError, "Status must be a Fixnum or a Range (it's a #{matchers[:status].class.name})"
      end if matchers[:status]

      case matchers[:ip].class.name
        when String.name then @match_ip_s = matchers[:ip]
        when Regexp.name then @match_ip_r = matchers[:ip]
        else raise ArgumentError, "IP must be a String or a Regexp (it's a #{matchers[:ip].class.name})"
      end if matchers[:ip]

      case matchers[:format].class.name
        when Symbol.name then @match_format_s = matchers[:format].to_s.downcase.to_sym
        when Array.name then @match_format_a = matchers[:format].map { |f| f.to_s.downcase.to_sym }
        else raise ArgumentError, "Format must be a Symbol or an Array (it's a #{matchers[:format].class.name})"
      end if matchers[:format]

      case matchers[:longer_than].class.name
        when Fixnum.name then @match_longer = matchers[:longer_than]
        else raise ArgumentError, "longer_than must be a Fixnum (it's a #{matchers[:longer_than].class.name})"
      end if matchers[:longer_than]

      case matchers[:shorter_than].class.name
        when Fixnum.name then @match_shorter = matchers[:shorter_than]
        else raise ArgumentError, "shorter_than must be a Fixnum (it's a #{matchers[:shorter_than].class.name})"
      end if matchers[:shorter_than]

      if matchers[:before]
        @match_before = if matchers[:before].is_a? Time
          matchers[:before]
        elsif matchers[:before].is_a? Date
          Utils::NormalizedTime.new(matchers[:before].year, matchers[:before].month, matchers[:before].day)
        else
          raise ArgumentError, "before must be a Date or Time (it's a #{matchers[:before].class.name})"
        end
      end

      if matchers[:after]
        @match_after = if matchers[:after].is_a? Time
          matchers[:after]
        elsif matchers[:after].is_a? Date
          Utils::NormalizedTime.new(matchers[:after].year, matchers[:after].month, matchers[:after].day)
        else
          raise ArgumentError, "after must be a Date or Time (it's a #{matchers[:after].class.name})"
        end
      end

      if matchers[:on]
        if matchers[:on].is_a? Date
          @match_on = matchers[:on]
        else
          raise ArgumentError, "on must be a Date (it's a #{matchers[:on].class.name})"
        end
      end

      case matchers[:params_str].class.name
        when Regexp.name then @match_params_str = matchers[:params_str]
        else raise ArgumentError, "Params String must be a Regexp (it's a #{matchers[:params_str].class.name})"
      end if matchers[:params_str]

      case matchers[:params].class.name
        when Hash.name then @match_params = matchers[:params]
        else raise ArgumentError, "Params must be a String or a Regexp (it's a #{matchers[:params].class.name})"
      end if matchers[:params]

      case matchers[:match].class.name
        when Regexp.name then @match_r = matchers[:match]
        else raise ArgumentError, "Match must be a Regexp (it's a #{matchers[:match].class.name})"
      end if matchers[:match]
    end
  end
end
