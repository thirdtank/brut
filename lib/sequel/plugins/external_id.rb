module Sequel
  module Plugins
    module ExternalId
      def self.apply(model,*args,&block)
        @global_prefix = (args.first || {})[:global_prefix]
      end

      module ClassMethods
        attr_reader :global_prefix
        def has_external_id(prefix)
          global_prefix = find_global_prefix
          @external_id_prefix = RichString.new("#{global_prefix}#{prefix}").to_s_or_nil
        end

        def external_id_prefix = @external_id_prefix

        def find_global_prefix(receiver=self)
          if receiver.respond_to?(:global_prefix)
            if receiver.global_prefix.nil?
              receiver.ancestors.select { |ancestor| ancestor != receiver }.map { |ancestor|
                self.find_global_prefix(ancestor)
              }.compact.first
            else
              receiver.global_prefix
            end
          else
            nil
          end
        end
      end

      module InstanceMethods
        def before_save
          if self.class.external_id_prefix
            if self.external_id.nil?
              random_hex = SecureRandom.hex
              self.external_id = "#{self.class.external_id_prefix}_#{random_hex}"
            end
          end
          super
        end
      end
    end
  end
end
