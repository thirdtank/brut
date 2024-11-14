module Sequel
  module Plugins
    module CreatedAt
      module InstanceMethods
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
