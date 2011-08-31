# Not specifically a performance analyzer (like https://github.com/wvanbergen/request-log-analyzer/wiki)
# Rather, a DSL for finding out how people are using your Rails app (which could include performance).
module Beaver
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

  class Beaver
    attr_reader :files, :dams, :requests

    # Pass in globs or file paths
    def initialize(*args)
      @files = args.map { |a| Dir.glob(a) }
      @files.flatten!
      @requests, @dams, @sums = [], {}, {}
    end

    # Creates a new Dam and appends it to this Beaver. name should be a unique symbol.
    # See Beaver::Dam for available options.
    def hit(dam_name, matchers={}, &callback)
      raise ArgumentError, "A dam named #{dam_name} already exists" if @dams.has_key? dam_name
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
        @dams[dam_name].instance_eval(&callback)
      end
    end

    # Parse the logs into @requests
    def parse
      @files.each do |file|
        zipped = file =~ /\.gz\Z/i
        next if zipped and not defined? Zlib
        File.open(file, 'r') do |f|
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
