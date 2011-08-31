module Beaver
  class Dam
    attr_reader :name, :callback, :hits

    # Name should be a unique symbol.
    # 
    # Matchers:
    #
    #  :path => String for exact match, or Regex
    #
    #  :method => A Symbol of :get, :post, :update or :delete, or any array of any (reads the magic _method field if present)
    #
    #  :status => A Fixnum like 404 or a Range like (500..503)
    # 
    #  :ip => String for exact match, or Regex
    # 
    #  :params => A Hash of Symbol=>String/Regexp pairs: {:username => 'bob', :email => /@gmail\.com$/}. All must match.
    # 
    # The last argument may be a block, which will be called everytime this Dam is hit.
    # The block will be run in the context of the Request and will have access to the above options as methods.
    # This can be used for reporting purposes, or you may do further checks on the hit to see if it's really
    # a match. If not, "throw :skip" to ignore it.
    def initialize(name, matchers, &callback)
      @name = name
      @callback = callback
      @hits = []
      set_matchers(matchers)
    end

    def ips
      @ips ||= @hits.map(&:ip).uniq
    end

    def matches?(request)
      checks = 0
      trues = 0
      if @match_path_s
        checks += 1
        trues += 1 if @match_path_s == request.path
      end
      if @match_path_r
        checks += 1
        trues += 1 if @match_path_r =~ request.path
      end
      if @match_method_s
        checks += 1
        trues += 1 if @match_method_s == request.method
      end
      if @match_method_a
        checks += 1
        trues += 1 if @match_method_a.include? request.method
      end
      if @match_status
        checks += 1
        trues += 1 if @match_status === request.status
      end
      if @match_ip_s
        checks += 1
        trues += 1 if @match_ip_s == request.ip
      end
      if @match_ip_r
        checks += 1
        trues += 1 if @match_ip_r =~ request.ip
      end
      if @match_params
        checks += 1
        trues += 1 if matching_hashes? @match_params, request.params
      end
      checks == trues
    end

    private

    def matching_hashes?(a,b)
      intersecting_keys = a.keys & b.keys
      if intersecting_keys.any?
        a_values = a.values_at(intersecting_keys)
        b_values = b.values_at(intersecting_keys)
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

    def set_matchers(matchers)
      case matchers[:path].class.name
        when String.name then @match_path_s = matchers[:path]
        when Regexp.name then @match_path_r = matchers[:path]
        else raise ArgumentError, "Path must be either a String or a Regexp (it's a #{matchers[:path].class.name})"
      end if matchers[:path]

      case matchers[:method].class.name
        when Symbol.name then @match_method_s = matchers[:method]
        when Array.name then @match_method_a = matchers[:method]
        else raise ArgumentError, "Method must be either a Symbol or an Array (it's a #{matchers[:method].class.name})"
      end if matchers[:method]

      case matchers[:status].class.name
        when Fixnum.name, Range.name then @match_status = matchers[:status]
        else raise ArgumentError, "Status must be either a Fixnum or a Range (it's a #{matchers[:status].class.name})"
      end if matchers[:status]

      case matchers[:ip].class.name
        when String.name then @match_status_s = matchers[:ip]
        when Regexp.name then @match_status_r = matchers[:ip]
        else raise ArgumentError, "IP must be either a String or a Regexp (it's a #{matchers[:ip].class.name})"
      end if matchers[:ip]

      case matchers[:params].class.name
        when Hash.name then @match_params = matchers[:params]
        else raise ArgumentError, "IP must be either a String or a Regexp (it's a #{matchers[:params].class.name})"
      end if matchers[:params]
    end
  end
end
