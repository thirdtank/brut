require "set"
require "opentelemetry-sdk"

# Allows instrumentation of methods via a class method. While Pages, Handlers, and Components are generally
# instrumented, this module can be used for your back-end classes (or private methods of pages, handlers, or
# component).
#
# @example Instrument specific methods
#   class Widget
#     include Brut::Instrumentation::Methods
#
#     def save
#       # ...
#     end
#
#     def search
#       # ...
#     end
#
#     instrument :save # search is not instrumented
#   end
#
# @example Instrument all methods
#   class Widget
#     include Brut::Instrumentation::Methods
#
#     instrument_all!
#
#     def save
#       # ...
#     end
#
#     def search
#       # ...
#     end
#
#   private
#
#     def delete_orphans
#     end
#   end
module Brut::Instrumentation::Methods

  # @!visibility private
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def __module_for_instrumented_methods
      @__module_for_instrumented_methods ||= begin
        mod = Module.new
        prepend mod
        mod
      end
    end

    # Instrument methods that have already been defined.
    #
    # @param method_names [Array<Symbol>] the method names to instrument.  They must
    #                     exist and they must not already have been instrumented.
    # @raise [ArgumentError] if any method does not exist or has already been instrumented
    def instrument(*method_names)

      method_names.each do |method_name|
        if __module_for_instrumented_methods.method_defined?(method_name)
          raise ArgumentError, "Method #{method_name} is already instrumented in #{self}"
        end

        method_defined = method_defined?(method_name) ||
                         private_method_defined?(method_name) ||
                         protected_method_defined?(method_name)

        if !method_defined
          raise ArgumentError, "Method #{method_name} is not defined in #{self.name}"
        end

        visibility = if private_method_defined?(method_name)
                       :private
                     elsif protected_method_defined?(method_name)
                       :protected
                     else
                       :public
                     end

        __module_for_instrumented_methods.module_eval do
          define_method(method_name) do |*args, **kwargs, &blk|
            span_name = "#{self.class.name}##{method_name}"
            span_attrs = {
              "brut.class" => self.class.name,
              "brut.method"  => method_name.to_s,
            }

            Brut.container.instrumentation.span(span_name, attributes: span_attrs) do |span|
              super(*args, **kwargs, &blk)
            end
          end

          # match original visibility
          send(visibility, method_name)
        end
      end
      nil
    end

    # Instrument all methods, public, protected, and private, other than `initialize`.
    # This will also instrument any methods defined in this class after it's called, meaning
    # you can it at the top of the class.  Do note that this will not instrument any
    # methods brought in via modules.
    def instrument_all
      @__instrument_all = true
      method_names = instance_methods(false) + private_instance_methods(false) - [ :initialize ]

      instrument(*method_names)

      nil
    end

    # Instrument all public and protected methods, other than `initialize`.
    # This will also instrument any public or protected methods defined in this class after it's called,
    # meaning you can it at the top of the class.  Do note that this will not instrument any
    # methods brought in via modules.
    def instrument_public
      @__instrument_public = true
      method_names = instance_methods(false) - [ :initialize ]

      instrument(*method_names)

      nil
    end

    def method_added(meth)
      if !@__instrument_all && !@__instrument_public
        return
      end
      if @__adding__
        return
      end
      if meth == :initialize
        return
      end
      if !@__instrument_all && private_instance_methods(false).include?(meth)
        return
      end

      @__adding__ = true
      instrument(meth)
      @__adding__ = false
    end
  end
end

