# Subclass this in your back-end to create a server-side
# validator for your form.  This provides for a much
# richer set of validations than you get from the browser, but
# works basically the same way.
class Brut::BackEnd::Validators::FormValidator
  def self.validate(attribute,options)
    @@validations ||= {}
    @@validations[attribute] = options
  end

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
