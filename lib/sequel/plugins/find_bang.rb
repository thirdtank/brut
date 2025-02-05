module Sequel
  module Plugins
    # Adds {ClassMethods#find!} to all models, which behaves as it does in Rails.
    module FindBang
      module ClassMethods
        # Calls `first!`, but provides a more helpful error message when no records are found.
        # @raise [Brut::Framework::Errors::NotFound]
        def find!(**args)
          self.first!(**args)
        rescue Sequel::NoMatchingRow => ex
          raise Brut::Framework::Errors::NotFound.new(resource_name: self.name,search_terms: args.inspect,context: ex.message)
        end
      end
    end
  end
end
