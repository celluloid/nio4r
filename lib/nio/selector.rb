require 'monitor'

module NIO
  # Selectors monitor IO objects for events of interest
  class Selector
#    def initialize
#      @selectables = {};
#      @lock = ::Monitor.new
#      super
#    end
    
    
    # Register interest in an IO object with the selector for the given types
    # of events. Valid event types for interest are:
    # * :r - is the IO readable?
    # * :w - is the IO writeable?
    # * :rw - is the IO either readable or writeable?
    def register(io, interests)
      super(coerce_io(io), interests)
    end
    
    # Deregister the given IO object from the selector
    def deregister(io)
      super(coerce_io(io))
    end
    
    # def reregister(monitor)
    #   native_reregister(monitor)
    # end

    # Is the given IO object registered with the selector?
    def registered?(io)
      super(coerce_io(io))
    end
    
    def [](io)
      super(coerce_io(io))
    end
    
    def select(timeout = nil, &block)
      raise ArgumentError, "time interval must be positive" if(timeout && timeout < 0)
      super(timeout, &block)
    end
    
    def self.lock_methods(*methods)
      methods.each do |m|
        mname = :"#{m}_without_lock"
        define_method :"#{m}_with_lock" do |*args, &block|
          # @lock.synchronize do
            send mname, *args, &block
          # end
        end
        alias_method :"#{m}_without_lock", m
        alias_method m, :"#{m}_with_lock"
      end
    end
    
    def self.threadsafe!
      lock_methods :select, :register, :reregister, :deregister, :registered?, :close, :closed?, :empty?
    end
    
    protected
    
    def coerce_io(io)
      return io if io.is_a?(IO)
      if IO.respond_to? :try_convert
        io = IO.try_convert(io)
      elsif io.respond_to? :to_io
        io = io.to_io
      end
      raise TypeError, "can't convert #{io.class} into IO" unless io.is_a? IO
      io
    end
    
    #
    # An optional helper module that can be mixed into Selector to provide [] and []= operators to hold monitors
    #
    module Selectables
      def initialize(*args)
        super(*args)
        @selectables = {}
      end

      def register(io, interests)
        m = (@selectables[io] = Monitor.new(io, interests, self))
        super(m)
      end
      
      def deregister(io)
        m = @selectables.delete(io)
        super(m)
      end
      
      def registered?(io)
        @selectables.has_key?(io)
      end
      
      def empty?
        @selectables.empty?
      end
      
      #Lookup a monitor by io object
      def [](io)
        @selectables[io]
      end
    end
  end
end
