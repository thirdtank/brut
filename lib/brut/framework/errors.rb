module Brut
  module Framework
    module Errors
      autoload(:Bug,"brut/framework/errors/bug")
      autoload(:NotFound,"brut/framework/errors/not_found")
      autoload(:AbstractMethod,"brut/framework/errors/abstract_method")
      def bug!(message=nil)
        raise Brut::Framework::Errors::Bug,message
      end
    end
    class Error < StandardError
    end
  end
end
