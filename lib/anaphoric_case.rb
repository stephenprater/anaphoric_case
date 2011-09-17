require 'pry'

module AnaphoricCase
  @__nest = 0
  class << self
    # @private
    attr_accessor :__nest 

    def switch_stack
      Thread.current[:__switch_stack] ||= []
    end
  end
end

module Kernel
  # aif - anaphoric if.
  #
  # English is nice, in that if you want to make a conditional, you can say 
  # "if the dog is on fire, then put it out!" to say the equivalent thing in Ruby 
  # you say "if the dog is on fire, then put the dog out." - which is fine, if something
  # of a hassle sometimes.  The "it" in the first example is an anaphor - 
  # 
  # @param [Object] result - any object, although it generally take the form of an expression.
  # @return [Object, FalseClass] returns the results of the block if the paramater was
  #   truthy (ie, it wasn't `nil` or `false`) or FalseClass if it wasn't
  # @yield [Object] yields the parameter into a block if it's truthy, the block can optionally return
  #   a different value, which will become the return value of #aif
  def aif result = true, &block
    if result
      unless block.nil? then result = block.call(*[result].slice(0,block.arity)) end
      return result
    end
    false
  end

  # switch - anaphoric case construct
  #
  # this is basically a form of sugar over a whole list of || operators or +or+ statements
  # @example
  #   thing = switch do
  #     on object.quick_method_that_might_return_nil
  #     on object.medium_method_that_might_return_nil
  #     on object.slow_method_that_might_return_nil
  #     on { raise 'everything returned nil!' }
  #   end
  #   # thing will be equal to results of the first method that 
  #   # didn't return nil
  # 
  # This prevents you from either writing a difficult to read list of || operators, or
  # having to construct lazily evaluated list of methods and parameters in order to do
  # the cheapest thing.
  # @param [Object] object - 
  #   parameter of all +on+ calls will be compared to this object using +===+
  #   @note if you plan on passing an object which could be nil to the method,
  #     you should call {Object#nil?} on it as your first +on+ condition as otherwise
  #     it will always match the first one.
  # @yield A block during which the +on+ method will be available - the block is required.
  #   The block is always executed in the context of the receiver of the +switch+ method
  #   so most of the time this is +self+ but if you call +switch+ with an explicit receiver
  #   it acts somewhat like the {Object#tap} method
  # @raise [ArgumentError] I tried to tell you the callable or block was required
  # @return [Object, FalseClase] the results of the first call to +on+ that returned 
  #   anything truthy, or of its block
  def switch object = nil, &block
    AnaphoricCase.__nest += 1
    
    raise ArgumentError, "switch requires a block" unless block_given? 
    block = block.dup # enable cross thread sharing of blocks
    
    class << self
      def on result = true, &block
        # the current switch block in this thread
        it = AnaphoricCase.switch_stack.last.instance_eval { @it }

        begin
          if it and (result === it or result == true)
            result = Kernel.aif it, &block
            throw :result, result if result
          elsif result and not it
            result = Kernel.aif result, &block
            throw :result, result if result
          end
        rescue ArgumentError => e
          if e.message =~ /throw :result/
            raise NameError, "on without associated switch"
          else
            raise e
          end
        end
        false
      end
    end
    
    block.instance_eval do
      @it = object
    end 
    AnaphoricCase.switch_stack << block

    res = catch :result do
      if block.arity > 0 
        self.instance_exec(object, &block)
      else
        self.instance_eval(&block)
      end
    end
    res ? res : false
 
  ensure
    AnaphoricCase.__nest -= 1
    Thread.current[:__switch_stack].pop if object
    if AnaphoricCase.__nest == 0
      class << self
        #you can get here without the on method being defined,
        #so rescue this silently if so.
        remove_method :on rescue nil
      end
    end
  end

  # on
  #
  # the +on+ method is available only in the {#switch} block - it basically
  # functions exactly like the aif method.
  # 
  # The first +on+ method whose argument is truthy will execute it's block and
  # cause switch to return the value of the block.
  # @see #aif
  # @see #switch
  # @param [Object] result - any object, normally an expression 
  #   it defaults to true, so you can use an +on+ without an argument as a default clause
  # @raise [NameError] if called from outside of a switch block or across
  #   the stack rewinding barrier
  # @yield [Object] yields the parameter into the block, which can optionally
  #   return a different value. <br/> if the block of an +on+ returns +nil+ or +false+,
  #   evaluation will continue at the next call to +on+. If the block is ommitted
  #   the parameter passed to +on+ will be returned (by {#switch})
  def on result=true; super; end
  remove_method :on
end
