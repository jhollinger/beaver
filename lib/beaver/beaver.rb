# A DSL and library for finding out how people are using your Rails app.
# Can also be used to parse/analyze HTTP access logs (Apache, Nginx, etc.)
#
#  # Parse and return the requests
#  requests = Beaver.parse('/path/to/log/files')
#
#  # Parse, filters, and returns the requests (all requests are always returned)
#  requests = Beaver.filter('/path/to/log/files') do
#    hit :error, :status => (400..505) do
#      puts "#{status} on #{path} at #{time} from #{ip} with #{params_str}"
#    end
#  end
# 
#  # Parse and filters the requests, returns nil
#  Beaver.stream('/path/to/log/files') do
#    hit :error, :status => (400..505) do
#      puts "#{status} on #{path} at #{time} from #{ip} with #{params_str}"
#    end
#  end
# 
module Beaver
  # Parses the logs and returns the requests.
  def self.parse(*args)
    Beaver.new(*args).parse.requests
  end

  # Parses the logs and filters them through the given block. *All* parsed requests 
  # are returned, not just the ones that matched. This is useful for when you take your action(s) on the matching reqeusts *inside* the block, but you still want access to all the requsts afterwords.
  def self.filter(*args, &blk)
    Beaver.new(*args, &blk).parse.filter.requests
  end

  # Parses the logs and filters them through the (optional) block. Parsed requests are
  # not retained, hence are not returned. Returns nil.
  # 
  # In theory, this should be more memory efficient than Beaver#filter.
  def self.stream(*args, &blk)
    Beaver.new(*args, &blk).stream
    nil
  end

  # Parses the logs and filters them through the provided matcher options. Returns *only* the matching requests.
  def self.dam(*args)
    beaver = Beaver.new(*args)
    dam = beaver.hit :hits
    beaver.parse
    beaver.filter
    dam.hits
  end

  # Alias to Beaver::Beaver.new
  def self.new(*args, &blk)
    Beaver.new(*args, &blk)
  end

  # The Beaver class, which keeps track of the files you're parsing, the Beaver::Dam objects you've defined,
  # and parses and filters the matching Beaver::Request objects.
  # 
  #  beaver = Beaver.new do
  #    hit :help, :path => '/help' do
  #      puts "#{ip} needed help"
  #    end
  #  end
  # 
  #  # Method 1 - logs will be parsed and filtered line-by-line, then discarded. Performance should be constant regardless of the number of logs.
  #  beaver.stream
  # 
  #  # Method 2 - all of the logs will be parsed at once and stored in "beaver.requests". Then each request will be filtered.
  #  # This does not scale as well, but is necessary *if you want to hang onto the parsed requests*.
  #  beaver.parse.filter
  # 
  class Beaver
    # The log files to parse
    attr_reader :logs
    # Parse stdin (ignores tty)
    attr_accessor :stdin
    # Enables parsing from tty *if* @stdin in also true
    attr_accessor :tty
    # The Beaver::Dam objects you're defined
    attr_reader :dams
    # The Beaver::Request objects matched in the given log files (only availble with Beaver#parse)
    attr_reader :requests

    # Pass in globs or file paths. The final argument may be an options Hash.
    # These options will be applied as matchers to all hits. See Beaver::Dam for available options.
    def initialize(*args, &blk)
      @global_matchers = args.last.is_a?(Hash) ? args.pop : {}
      @logs = args.map { |a| Dir.glob(a) }
      @logs.flatten!
      @stdin, @tty = false, false
      @requests, @dams, @sums = [], {}, {}
      instance_eval(&blk) if block_given?
    end

    # Creates a new Dam and appends it to this Beaver. name should be a unique symbol.
    # See Beaver::Dam for available options.
    def hit(dam_name, matchers={}, &callback)
      $stderr.puts "WARNING Overwriting existing hit '#{dam_name}'" if @dams.has_key? dam_name
      matchers = @global_matchers.merge matchers
      @dams[dam_name] = Dam.new(dam_name, matchers, &callback)
    end

    # Define a sumarry for a Dam
    def dam(name, hit_options={}, &callback)
      $stderr.puts "WARNING Overwriting existing dam '#{name}'" if @sums.has_key? name
      @sums[name] = callback
      # Optionally create a new hit
      hit(name, hit_options) if @dams[name].nil?
    end

    # Parses the logs and immediately filters them through the dams. Requests are not retained,
    # so this should scale better to very large sets of logs.
    def stream
      # Match the request against each dam, and run the dam's callback
      _parse do |request|
        hit_dams(request) do |dam|
          dam.hits << request if @sums[dam.name]
        end
      end
      # Run the callback for each summary
      summarize_dams do |dam|
        dam.hits.clear # Clean up
      end
      self
    end

    # Filter @requests through the dams. (Beaver#parse must be run before this, or there will be no @requests.)
    # Requests will be kept around after the run.
    def filter
      for request in @requests
        hit_dams(request) do |dam|
          dam.hits << request
        end
      end
      summarize_dams
      self
    end

    # Parse the logs into @requests. This does *not* run them through the dams. To do that call Beaver#filter afterwards.
    def parse
      @requests.clear
      _parse { |request| @requests << request }
      self
    end

    # Tells this Beaver to look in STDIN for log content to parse. NOTE This ignores tty input unless you also call Beaver#tty!.
    # 
    # *Must* be called before "stream" or "parse" to have any effect. Returns "self," so it is chainable. Can also be used in the DSL.
    def stdin!
      @stdin = true
      self
    end

    # Tells this Beaver to look in STDIN for tty input.
    # 
    # *Must* be called before "stream" or "parse" to have any effect. Returns "self," so it is chainable. Can also be used in the DSL.
    def tty!
      stdin!
      @tty = true
      self
    end

    private

    # Run the callback on each dam matching request. Optionally pass a block, which will be passed back matching dams.
    def hit_dams(request, &blk)
      for dam in @dams.values
        if dam === request
          catch :skip do
            request.instance_eval(&dam.callback) if dam.callback
            blk.call(dam) if block_given?
          end
        end
      end
    end

    # Run the summary callback for each dam that had matching requests. Optionally pass a block, which will be passed back each dam.
    def summarize_dams(&blk)
      for dam_name, callback in @sums
        if @dams.has_key? dam_name
          if @dams[dam_name].hits.any?
            @dams[dam_name].instance_eval(&callback)
            blk.call(@dams[dam_name]) if block_given?
          end
        else
          $stderr.puts "WARNING You have defined a dam for '#{dam_name}', but there is no hit defined for '#{dam_name}'"
        end
      end
    end

    # Parses @logs into requests, and passes each request to &blk.
    def _parse(&blk)
      request = nil
      # Parses a line into part of a request
      parse_it = lambda { |line|
        if request
          request << line
        else
          request = Request.for(line)
          next if request.nil?
        end
        if request.invalid?
          request = Request.for(line)
        elsif request.completed?
          blk.call(request)
          request = nil
        end
      }

      # Parse stdin
      if @tty
        STDIN.read.each_line &parse_it # Read entire stream, then parse it - looks much better to the user
      elsif !STDIN.tty?
        begin
          STDIN.each_line &parse_it
        rescue Interrupt
          $stderr.puts 'Closing input stream; parsing input...'
        end
      end if @stdin
      request = nil

      # Parse log files
      for file in @logs
        zipped = file =~ /\.gz\Z/i
        next if zipped and not defined? Zlib
        File.open(file, 'r:UTF-8') do |f|
          handle = (zipped ? Zlib::GzipReader.new(f) : f)
          handle.each_line &parse_it
        end
      end
    end
  end
end
