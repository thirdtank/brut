module Sequel
  module Plugins
    module FindBang
      module ClassMethods
        def find!(**args)
          self.first!(**args)
        rescue Sequel::NoMatchingRow => ex
          raise Sequel::NoMatchingRow.new(ex.message + "; #{args.inspect}")
        end
      end
    end
  end
end
