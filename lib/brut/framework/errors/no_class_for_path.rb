# Raised when a path has been declared, but the class to handle it cannot be found in the app.
class Brut::Framework::Errors::NoClassForPath < Brut::Framework::Error
  # Array of names that, if joined with `::` would name the class that could not be found
  # @return [Array<String>] array of parts. For a class named `Auth::LoginPage`, would return `["Auth","LoginPage"]`
  attr_reader :class_name_path
  # The path template that the class that couldn't be found was intended to handle
  # @return [String] a path template as given inside {Brut::Framework::App.routes}
  attr_reader :path_template

  # Create the exception
  # @param [Array<String>] class_name_path array of names that, if joined with `::` would name the class that could not be found
  # @param [String] path_template The path template that the class that couldn't be found was intended to handle
  # @param [NameError] name_error The `NameError` that was caught
  def initialize(class_name_path:, path_template:, name_error:)
    @class_name_path = class_name_path
    @path_template = path_template
    module_message = if name_error.receiver == Module
                       "Could not find"
                     else
                       "Module '#{name_error.receiver}' did not have"
                     end
    message = "Cannot find page class for route '#{path_template}', which should be #{class_name_path.join("::")}. #{module_message} the class or module '#{name_error.name}'"
    super(message)
  end
end
