# Not specifically a performance analyzer (like https://github.com/wvanbergen/request-log-analyzer/wiki)
# Rather, a DSL for finding out how people are using your Rails app (which could include performance).
# 
# Beaver.stream do
#   hit :error, :status => (400..505) do
#     puts "#{status} on #{path} at #{time} from #{ip} with #{params_str}"
#   end
# end
# 
module Beaver
  MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION = 1, 0, 0, nil
  VERSION = [MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION].compact.join '.'

  # Creates a new Beaver and immediately filters the log files. This should scale well
  # for even very large logs, at least when compared to Beaver#parse.
  def self.stream(*args, &blk)
    raise ArgumentError, 'You must pass a block to Beaver#stream' unless block_given?
    Beaver.new(*args, &blk).stream
  end

  # Identical to Beaver#stream, except that the requests are retained, so you may
  # examine them afterwards. For large logs, this may be noticibly inefficient.
  def self.parse(*args, &blk)
    raise ArgumentError, 'You must pass a block to Beaver#parse' unless block_given?
    Beaver.new(*args, &blk).parse.filter
  end

  # Alias to creating a new Beaver
  def self.new(*args, &blk)
    Beaver.new(*args, &blk)
  end

  # The Beaver class, which keeps track of the files you're parsing, the Beaver::Dam objects you've defined,
  # and parses and filters the matching Beaver::Request objects.
  # 
  # beaver = Beaver.new do
  #   hit :help, :path => '/help' do
  #     puts "#{ip} needed help"
  #   end
  # end
  # 
  # # Method 1 - logs will be parsed and filtered line-by-line, then discarded. Performance should be constant regardless of the number of logs.
  # beaver.stream
  # 
  # # Method 2 - all of the logs will be parsed at once and stored in "beaver.requests". Then each request will be filtered.
  # # This does not scale as well, but is necessary *if you want to hang onto the parsed requests*.
  # beaver.parse.filter
  # 
  class Beaver
    # The files to parse
    attr_reader :files
    # The Beaver::Dam objects you're defined
    attr_reader :dams
    # The Beaver::Request objects matched in the given files (only availble with Beaver#parse)
    attr_reader :requests

    # Pass in globs or file paths. The final argument may be an options Hash.
    # These options will be applied as matchers to all hits. See Beaver::Dam for available options.
    def initialize(*args, &blk)
      @global_matchers = args.last.is_a?(Hash) ? args.pop : {}
      @files = args.map { |a| Dir.glob(a) }
      @files.flatten!
      @requests, @dams, @sums = [], {}, {}
      instance_eval(&blk) if block_given?
    end

    # Creates a new Dam and appends it to this Beaver. name should be a unique symbol.
    # See Beaver::Dam for available options.
    def hit(dam_name, matchers={}, &callback)
      STDERR.puts "WARNING Overwriting existing hit '#{dam_name}'" if @dams.has_key? dam_name
      matchers = @global_matchers.merge matchers
      @dams[dam_name] = Dam.new(dam_name, matchers, &callback)
    end

    # Define a sumarry for a Dam
    def dam(name, &callback)
      STDERR.puts "WARNING Overwriting existing dam '#{name}'" if @sums.has_key? name
      @sums[name] = callback
    end

    # Parses the logs and immediately filters them through the dams. Requests are not retained,
    # so this should scale well to very large sets of logs.
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

    private

    # Run the callback on each dam matching request. Optionally pass a block, which will be passed back matching dams.
    def hit_dams(request, &blk)
      for dam in @dams.values
        if dam.matches? request
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
          STDERR.puts "WARNING You have defined a dam for '#{dam_name}', but there is no hit defined for '#{dam_name}'"
        end
      end
    end

    # Parses @files into requests, and passes each request to &blk.
    def _parse(&blk)
      for file in @files
        zipped = file =~ /\.gz\Z/i
        next if zipped and not defined? Zlib
        File.open(file, 'r:UTF-8') do |f|
          handle = (zipped ? Zlib::GzipReader.new(f) : f)
          request = nil
          handle.each_line do |line|
            request = Request.for(line).new if request.nil?
            if request.bad?
              request = nil
              next
            end
            request << line
            if request.completed?
              blk.call(request)
              request = nil
            end
          end
        end
      end
    end
  end
end
