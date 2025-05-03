module Brut
  module Framework
    # Namespace for Brut-specific error classes, and a holder of several error-related convienience 
    # methods.  Include this module to gain access to those methods.
    module Errors
      autoload(:Bug,"brut/framework/errors/bug")
      autoload(:NotImplemented,"brut/framework/errors/not_implemented")
      autoload(:NotFound,"brut/framework/errors/not_found")
      autoload(:MissingParameter,"brut/framework/errors/missing_parameter")
      autoload(:MissingConfiguration,"brut/framework/errors/missing_configuration")
      autoload(:AbstractMethod,"brut/framework/errors/abstract_method")
      autoload(:NoClassForPath,"brut/framework/errors/no_class_for_path")
      # Raises {Brut::Framework::Errors::Bug}, used to indicate a codepath is a bug.  "But, why write a
      # bug in the first place?" you may be asking.  Sometimes, a code path exists, but external factors
      # mean that it should never be executed.  Or, sometimes an API can be mis-used, but the current
      # state of the system is such that it would never be misused.
      #
      # This method allows you to indicate such situations and provide a meaningful explanation.
      #
      # @param message Message to include in the error
      # @raise [Brut::Framework::Errors::Bug]
      def bug!(message=nil)
        raise Brut::Framework::Errors::Bug,message
      end

      # Raises {Brut::Framework::Errors::AbstractMethod}, which is useful if you need to document
      # a method that a subclass must implement, but for which there is no useful default
      # implementation.
      #
      # @raise [Brut::Framework::Errors::AbstractMethod]
      def abstract_method!
        raise Brut::Framework::Errors::AbstractMethod
      end
    end
    # Base class for errors thrown by Brut classes. Generally, Brut will not create its own version
    # of an error that exists in the standard library, e.g. `ArgumentError`, so this is only a base class
    # for Brut-specific error conditions.
    class Error < StandardError
    end
  end
end
