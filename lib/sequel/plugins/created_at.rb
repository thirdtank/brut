module Sequel
  module Plugins
    # Automatically sets `created_at` on all models.
    module CreatedAt
      module InstanceMethods
        # @!visibility private
        def before_save
          if self.created_at.nil?
            self.created_at = Time.now
          end
          super
        end
      end
    end
  end
end
