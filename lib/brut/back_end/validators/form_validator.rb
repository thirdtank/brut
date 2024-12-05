# Provides a very light DSL to declaring server-side validations for your
# {Brut::FrontEnd::Form} subclass. Unlike Active Record, these validations aren't mixed-into another object.
# Your subclass of this class is a standalone object that will operate on a form.
#
# @example
#     # Suppose you are creating a widget with a name and description.
#     # The form requires name, but not description, however if
#     # the user initiates a "publish" action from that form, the description is
#     # required. This cannot be managed with HTML alone.
#     class WidgetPublishValidator < Brut::BackEnd::Validators::FormValidator
#       validate :description, required: true, minlength: 10
#     end
#
#     # Then, in your back-end logic somewhere
#
#     validator = WidgetPublishValidator.new
#     validator.validate(form)
#     if form.constraint_violations?
#       # return back to the user
#     else
#       # proceed with business logic
#     end
#
class Brut::BackEnd::Validators::FormValidator
  # Called inside the subclass body to indicate that a given form input should be validated based on the given options
  # @param [String|Symbol] input_name name of the input of the form
  # @param [Hash] options options describing the validation to perform.
  def self.validate(input_name,options)
    @@validations ||= {}
    @@validations[input_name] = options
  end

  # Validate the given form, calling {Brut::FrontEnd::Form#server_side_constraint_violation} on each validate failure found.
  #
  # @param [Brut::FrontEnd::Form] form the form to validate
  def validate(form)
    @@validations.each do |attribute,options|
      value = form.send(attribute)
      options.each do |option, option_value|
        case option
        when :required
          if option_value == true
            if value.to_s.strip == ""
              form.server_side_constraint_violation(input_name: attribute, key: :required)
            end
          end
        when :minlength
          if value.respond_to?(:length) || value.nil?
            if value.nil? || value.length < option_value
              form.server_side_constraint_violation(input_name: attribute, key: :too_short, context: { minlength: option_value })
            end
          else
            raise "'#{attribute}''s value (a '#{value.class}') does not respond to 'length' - :minlength cannot be used as a validation"
          end
        else
          raise "'#{option}' is not a recognized validation option"
        end
      end
    end
  end

end
