# Not specifically a performance analyzer (like https://github.com/wvanbergen/request-log-analyzer/wiki)
# Rather, a DSL for finding out how people are using your Rails app (which could include performance).
module Beaver
  MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION = 1, 0, 0, nil
  VERSION = [MAJOR_VERSION, MINOR_VERSION, TINY_VERSION, PRE_VERSION].compact.join '.'

  # Alias to creating a new Beaver, parsing the files, and filtering them
  def self.parse(*args, &blk)
    raise ArgumentError, 'You must pass a block to Beaver#parse' unless block_given?
    beaver = Beaver.new(*args)
    beaver.parse
    beaver.filter(&blk)
    beaver
  end

  # Alias to creating a new Beaver
  def self.new(*args)
    Beaver.new(*args)
  end

  # The Beaver class, which keeps track of the files you're parsing, the Beaver::Dam objects you've defined,
  # and parses and stores the matching Beaver::Request objects.
  class Beaver
    # The files to parse
    attr_reader :files
    # The Beaver::Dam objects you're defined
    attr_reader :dams
    # The Beaver::Request objects matched in the given files
    attr_reader :requests

    # Pass in globs or file paths. The final argument may be an options Hash.
    # These options will be applied as matchers to all hits. See Beaver::Dam for available options.
    def initialize(*args)
      @global_matchers = args.last.is_a?(Hash) ? args.pop : {}
      @files = args.map { |a| Dir.glob(a) }
      @files.flatten!
      @requests, @dams, @sums = [], {}, {}
    end

    # Creates a new Dam and appends it to this Beaver. name should be a unique symbol.
    # See Beaver::Dam for available options.
    def hit(dam_name, matchers={}, &callback)
      raise ArgumentError, "A dam named #{dam_name} already exists" if @dams.has_key? dam_name
      matchers = @global_matchers.merge matchers
      @dams[dam_name] = Dam.new(dam_name, matchers, &callback)
    end

    # Define a sumarry for a Dam
    def dam(name, &callback)
      raise ArgumentError, "Unable to find a Dam named #{name}" unless @dams.has_key? name
      @sums[name] = callback
    end

    # Parse the logs and filter them through the dams
    # "parse" must be run before this, or there will be no requests
    def filter(&blk)
      instance_eval(&blk) if block_given?
      @requests.each do |req|
        @dams.each_value do |dam|
          if dam.matches? req
            catch :skip do
              req.instance_eval(&dam.callback) if dam.callback
              dam.hits << req
            end
          end
        end
      end
      @sums.each do |dam_name, callback|
        @dams[dam_name].instance_eval(&callback) if @dams[dam_name].hits.any?
      end
    end

    # Parse the logs into @requests
    def parse
      @files.each do |file|
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
              @requests << request
              request = nil
            end
          end
        end
      end
    end
  end
end
