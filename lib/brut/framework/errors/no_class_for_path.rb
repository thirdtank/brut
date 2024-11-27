class Brut::Framework::Errors::NoClassForPath < Brut::Framework::Error
  attr_reader :class_name_path, :path_template
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
