module Sequel
  module Plugins
    # Configures models with an external id that can be safely shared publicly and safely rotated. The external
    # id is random, however it is prefixed with configurable strings that can indicate what type of model it represents.
    # This disambiguates ids when shared pubnlically or in internal tooling.
    #
    # This extension accepts a configuration option `global_prefix:` that is a string prepended to all external IDs.  This ensures
    # that your app's IDs clearly come from your app and not some other app that may be using external ids.
    #
    # To use external ids you must then call {ClassMethods#has_external_id} in your model. This method accepts a string which is
    # appended to the global prefix.  This is then *prepended* to a unique identifier.  The per-model external id prefix should
    # indicate the type of the model.  Note that it's not intended to be used programmatically—it's only for humans to quickly see
    # what type of thing an identifier represents.
    #
    # When {ClassMethods#has_external_id} is called on your model, the column `external_id` will be set on save if it has no value.
    #
    # @example
    #    class DB::Widget < AppDataModel
    #      has_external_id "wg"
    #    end
    #
    #    Sequel::Model.plugin :external_id, global_prefix: "my"
    #
    #    widget = DB::Widget.new(name: "flux capacitor")
    #    widget.external_id # => mywg_43792834f9c3a7
    module ExternalId
      # @!visibility private
      def self.apply(model,*args,&block)
        @global_prefix = (args.first || {})[:global_prefix]
      end

      module ClassMethods
      # @!visibility private
        attr_reader :global_prefix
        # Called inside a model's body to indicate that this model has an `external_id` that this plugin should manage and what
        # prefix should be used.  Calling this will also alter {InstanceMethods#to_s} to include this id in the string representation.
        #
        # @param prefix [String] a short string identfying the type of this model. It will be prepended to your external_id.
        def has_external_id(prefix)
          global_prefix = find_global_prefix
          @external_id_prefix = RichString.new("#{global_prefix}#{prefix}").to_s_or_nil
        end

        # @!visibility private
        def external_id_prefix = @external_id_prefix

        # @!visibility private
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
        # @!visibility private
        def before_save
          if self.class.external_id_prefix
            if self.external_id.nil?
              random_hex = SecureRandom.hex
              self.external_id = "#{self.class.external_id_prefix}_#{random_hex}"
            end
          end
          super
        end
        # Includes the external id in the super class' representation. This means you can include
        # models in Log messages without having to explicitly fetch the id.
        def to_s
          super.to_s + "[external_id:#{self.external_id}]"
        end
      end
    end
  end
end
