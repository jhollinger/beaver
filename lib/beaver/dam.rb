module Beaver
  # A Dam "traps" certain Requests, using one or more matching options. A request must meet *all* of the 
  # matching options specified.
  # 
  # The last argument may be a block, which will be called everytime this Dam is hit.
  # The block will be run in the context of the Request object. This can be used for 
  # further checks or for reporting purposes.
  # 
  # Matchers:
  #
  #  :path          Rails HTTP  String for exact match, or Regex
  #
  #  :method        Rails HTTP  Symbol of :get, :post, :put or :delete, or any array of any (reads the magic _method field if present)
  # 
  #  :controller    Rails       String like 'FooController' or a Regex like /foo/i
  # 
  #  :action        Rails       String like 'index' or a Regex like /(index)|(show)/
  #
  #  :status        Rails HTTP  Fixnum like 404 or a Range like (500..503)
  # 
  #  :ip            Rails HTTP  String for exact match, or Regex
  #
  #  :format        Rails       Symbol or array of symbols of response formats like :html, :json
  # 
  #  :longer_than   Rails       Fixnum n. Matches any request which took longer than n milliseconds to complete.
  # 
  #  :shorter_than  Rails       Fixnum n. Matches any request which took less than n milliseconds to complete.
  # 
  #  :before        Rails HTTP  Date or Time for which the request must have ocurred before
  # 
  #  :after         Rails HTTP  Date or Time for which the request must have ocurred after
  # 
  #  :on            Rails HTTP  Date - the request must have ocurred on this date
  # 
  #  :params_str    Rails HTTP  Regular expressing matching the Parameters string
  # 
  #  :params        Rails       Hash of Symbol=>String/Regexp pairs: {:username => 'bob', :email => /@gmail\.com$/}. All must match.
  # 
  #  :tagged        Rails       Comma-separated String or Array of Rails Tagged Logger tags. If you specify multiple tags, a request must have *all* of them.
  # 
  #  :size                HTTP  Fixnum matching the response size in bytes
  # 
  #  :smaller_than        HTTP  Fixnum matching the maximum response size in bytes
  # 
  #  :larger_than         HTTP  Fixnum matching the minimum response size in bytes
  # 
  #  :referer             HTTP  String for exact match, or Regex
  # 
  #  :referrer            HTTP  Alias to :referer
  # 
  #  :user_agent          HTTP  String for exact match, or Regex
  # 
  #  :match         Rails HTTP  A "catch-all" Regex that will be matched against the entire request string
  class Dam
    # The symbol name of this Beaver::Dam
    attr_reader :name
    # An optional callback when a Beaver::Request hits this Dam
    attr_reader :callback
    # An array of Beaver::Request objects that have hit this Dam
    attr_reader :hits

    # Name should be a unique symbol. Matchers is an options Hash. The callback will be evauluated within
    # the context of a Beaver::Request.
    def initialize(name, matchers={}, &callback)
      @name = name
      @callback = callback
      @hits = []
      build matchers
    end

    # Transforms arrays of values into rows with equally padded columns. 
    # Useful for generating table-like formatting of hits.
    # If delim is falsey, the columns will not be joined, but returned as arrays.
    # 
    # Example:
    #
    #  puts tablize { |hit| [hit.ip, hit.path, hit.status] }
    def tablize(delim=' ', &block)
      rows = Utils.tablize(hits.map &block)
      rows.map! { |cols| cols.join(delim) } if delim
      rows
    end

    # Returns an array of IP address that hit this Dam.
    def ips
      @ips ||= @hits.map(&:ip).uniq
    end

    # Returns true if the given Request hits this Dam, false if not.
    def matches?(request)
      return false if request.final?
      return false unless @match_path.nil? or @match_path === request.path
      return false unless @match_referer.nil? or @match_referer === request.referer
      return false unless @match_user_agent.nil? or @match_user_agent === request.user_agent
      return false unless @match_longer.nil? or @match_longer < request.ms
      return false unless @match_shorter.nil? or @match_shorter > request.ms
      return false unless @match_method_s.nil? or @match_method_s == request.method
      return false unless @match_method_a.nil? or @match_method_a.include? request.method
      return false unless @match_status.nil? or @match_status === request.status
      return false unless @match_controller.nil? or @match_controller === request.controller
      return false unless @match_action.nil? or @match_action === request.action.to_s or @match_action == request.action
      return false unless @match_ip.nil? or @match_ip === request.ip
      return false unless @match_format_s.nil? or @match_format_s == request.format
      return false unless @match_format_a.nil? or @match_format_a.include? request.format
      return false unless @match_before_time.nil? or @match_before_time > request.time
      return false unless @match_before_date.nil? or @match_before_date > request.date
      return false unless @match_after_time.nil? or @match_after_time < request.time
      return false unless @match_after_date.nil? or @match_after_date < request.date
      return false unless @match_on.nil? or @match_on == request.date
      return false unless @match_params_str.nil? or @match_params_str =~ request.params_str
      return false unless @match_size.nil? or @match_size == request.size
      return false unless @match_size_lt.nil? or request.size < @match_size_lt
      return false unless @match_size_gt.nil? or request.size > @match_size_gt
      return false unless @match_r.nil? or @match_r =~ request.to_s
      if @deep_tag_match
        return false unless @match_tags.nil? or (@match_tags.any? and request.tags_str and deep_matching_tags(@match_tags, request.tags))
      else
        return false unless @match_tags.nil? or (@match_tags.any? and request.tags_str and (@match_tags - request.tags).empty?)
      end
      return false unless @match_params.nil? or matching_hashes?(@match_params, request.params)
      return true
    end

    private

    # Matches tags recursively
    def deep_matching_tags(matchers, tags)
      all_tags_matched = nil
      any_arrays_matched = false
      for m in matchers
        if m.is_a? Array
          matched = deep_matching_tags m, tags
          any_arrays_matched = true if matched
        else
          matched = tags.include? m
          all_tags_matched = (matched && all_tags_matched != false) ? true : false
        end
      end
      return (all_tags_matched or any_arrays_matched)
    end

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

    public

    # Parses and checks the validity of the matching options passed to the Dam.
    # XXX Yikes this is long and ugly...
    def build(matchers)
      # Match path
      if matchers[:path].respond_to? :===
        @match_path = matchers[:path]
      else
        raise ArgumentError, "Path must respond to the '===' method; try a String or a Regexp (it's a #{matchers[:path].class.name})"
      end if matchers[:path]

      # Match HTTP referer
      referer = matchers[:referer] || matchers[:referrer]
      if referer.respond_to? :===
        @match_referer = referer
      else
        raise ArgumentError, "Referrer must respond to the '===' method; try a String or a Regexp (it's a #{referer.class.name})"
      end if referer

      # Match request method
      case
        when matchers[:method].is_a?(Symbol) then @match_method_s = matchers[:method].to_s.downcase.to_sym
        when matchers[:method].is_a?(Array) then @match_method_a = matchers[:method].map { |m| m.to_s.downcase.to_sym }
        else raise ArgumentError, "Method must be a Symbol or an Array (it's a #{matchers[:method].class.name})"
      end if matchers[:method]

      # Match Rails controller
      if matchers[:controller].respond_to? :===
        @match_controller = matchers[:controller]
      else
        raise ArgumentError, "Controller must respond to the '===' method; try a String or a Regexp (it's a #{matchers[:controller].class.name})"
      end if matchers[:controller]

      # Match Rails controller action
      if matchers[:action].respond_to? :=== or matchers[:action].is_a? Symbol
        @match_action = matchers[:action]
      else
        raise ArgumentError, "Action must respond to the '===' method or be a Symbol; try a String, Symbol or a Regexp (it's a #{matchers[:action].class.name})"
      end if matchers[:action]

      # Match response status
      case matchers[:status].class.name
        when Fixnum.name, Range.name then @match_status = matchers[:status]
        else raise ArgumentError, "Status must be a Fixnum or a Range (it's a #{matchers[:status].class.name})"
      end if matchers[:status]

      # Match request IP
      if matchers[:ip].respond_to? :===
        @match_ip = matchers[:ip]
      else
        raise ArgumentError, "IP must respond to the '===' method; try a String or a Regexp (it's a #{matchers[:ip].class.name})"
      end if matchers[:ip]

      # Match Rails' response format
      case
        when matchers[:format].is_a?(Symbol) then @match_format_s = matchers[:format].to_s.downcase.to_sym
        when matchers[:format].is_a?(Array) then @match_format_a = matchers[:format].map { |f| f.to_s.downcase.to_sym }
        else raise ArgumentError, "Format must be a Symbol or an Array (it's a #{matchers[:format].class.name})"
      end if matchers[:format]

      # Match Rails' response time (at least)
      case matchers[:longer_than].class.name
        when Fixnum.name then @match_longer = matchers[:longer_than]
        else raise ArgumentError, "longer_than must be a Fixnum (it's a #{matchers[:longer_than].class.name})"
      end if matchers[:longer_than]

      # Match Rails' response time (at most)
      case matchers[:shorter_than].class.name
        when Fixnum.name then @match_shorter = matchers[:shorter_than]
        else raise ArgumentError, "shorter_than must be a Fixnum (it's a #{matchers[:shorter_than].class.name})"
      end if matchers[:shorter_than]

      # Match HTTP response size
      case matchers[:size].class.name
        when Fixnum.name then @match_size = matchers[:size]
        else raise ArgumentError, "size must be a Fixnum (it's a #{matchers[:size].class.name})"
      end if matchers[:size]

      # Match HTTP response size (at most)
      case matchers[:smaller_than].class.name
        when Fixnum.name then @match_size_lt = matchers[:smaller_than]
        else raise ArgumentError, "size must be a Fixnum (it's a #{matchers[:smaller_than].class.name})"
      end if matchers[:smaller_than]

      # Match HTTP response size (at least)
      case matchers[:larger_than].class.name
        when Fixnum.name then @match_size_gt = matchers[:larger_than]
        else raise ArgumentError, "size must be a Fixnum (it's a #{matchers[:larger_than].class.name})"
      end if matchers[:larger_than]

      # Match before a request date
      if matchers[:before].is_a? Time
        @match_before_time = matchers[:before]
      elsif matchers[:before].is_a? Date
        @match_before_date = matchers[:before]
      else
        raise ArgumentError, "before must be a Date or Time (it's a #{matchers[:before].class.name})"
      end if matchers[:before]

      # Match after a request date or datetime
      if matchers[:after].is_a? Time
        @match_after_time = matchers[:after]
      elsif matchers[:after].is_a? Date
        @match_after_date = matchers[:after]
      else
        raise ArgumentError, "after must be a Date or Time (it's a #{matchers[:after].class.name})"
      end if matchers[:after]

      # Match a request date
      if matchers[:on].is_a? Date
        @match_on = matchers[:on]
      else
        raise ArgumentError, "on must be a Date (it's a #{matchers[:on].class.name})"
      end if matchers[:on]

      # Match request URL parameters string
      case matchers[:params_str].class.name
        when Regexp.name then @match_params_str = matchers[:params_str]
        else raise ArgumentError, "Params String must be a Regexp (it's a #{matchers[:params_str].class.name})"
      end if matchers[:params_str]

      # Match request URL parameters Hash
      case matchers[:params].class.name
        when Hash.name then @match_params = matchers[:params]
        else raise ArgumentError, "Params must be a String or a Regexp (it's a #{matchers[:params].class.name})"
      end if matchers[:params]

      # Match Rails request tags
      if matchers[:tagged]
        @match_tags = parse_tag_matchers(matchers[:tagged])
        @deep_tag_match = @match_tags.any? { |t| t.is_a? Array }
      end

      # Match HTTP user agent string
      if matchers[:user_agent].respond_to? :===
        @match_user_agent = matchers[:user_agent]
      else
        raise ArgumentError, "User Agent must respond to the '===' method; try a String or a Regexp (it's a #{matchers[:user_agent].class.name})"
      end if matchers[:user_agent]

      # Match the entire log entry string
      case matchers[:match].class.name
        when Regexp.name then @match_r = matchers[:match]
        else raise ArgumentError, "Match must be a Regexp (it's a #{matchers[:match].class.name})"
      end if matchers[:match]

      self
    end

    private

    # Recursively parses a tag match pattern
    def parse_tag_matchers(matcher)
      if matcher.is_a? String
        matcher.split(',').map { |t| t.strip.downcase }.uniq
      elsif matcher.is_a? Array
        matcher.map! do |m|
          if m.is_a?(Array) or (m.is_a?(String) and m =~ /,/)
            parse_tag_matchers(m)
          else m; end
        end
      else
        raise ArgumentError, "tagged must be a String or Array (it's a #{matcher.class.name})"
      end
    end
  end
end
