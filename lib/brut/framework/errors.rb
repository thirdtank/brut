module Brut
  module Framework
    # Include this in your class to access some helpful methods that throw commonly-needed
    # errors
    module Errors
      autoload(:Bug,"brut/framework/errors/bug")
      autoload(:NotImplemented,"brut/framework/errors/not_implemented")
      autoload(:NotFound,"brut/framework/errors/not_found")
      autoload(:MissingParameter,"brut/framework/errors/missing_parameter")
      autoload(:MissingConfiguration,"brut/framework/errors/missing_configuration")
      autoload(:AbstractMethod,"brut/framework/errors/abstract_method")
      autoload(:NoClassForPath,"brut/framework/errors/no_class_for_path")
      # Raises {Brut::Framework::Errors::Bug}
      #
      # @param message Message to include in the error
      # @raise [Brut::Framework::Errors::Bug]
      def bug!(message=nil)
        raise Brut::Framework::Errors::Bug,message
      end

      # Raises {Brut::Framework::Errors::AbstractMethod}
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
