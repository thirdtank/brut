module Sequel
  module Plugins
    # Adds {ClassMethods#find!} to all models, which behaves as it does in Rails.
    module FindBang
      module ClassMethods
        # Calls `first!`, but provides a more helpful error message when no records are found.
        def find!(**args)
          self.first!(**args)
        rescue Sequel::NoMatchingRow => ex
          raise Sequel::NoMatchingRow.new(ex.message + "; #{args.inspect}")
        end
      end
    end
  end
end
