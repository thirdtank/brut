# Indicates that a resource or database row does not exist.
class Brut::Framework::Errors::NotFound < Brut::Framework::Error
  # @param [String] resource_name Name of the type of resource
  # @param [String|Int] id Identifier of the resource
  # @param [String] context Any additional context about what went wrong
  def initialize(resource_name:,id:,context:nil)
    if !context.nil?
      context = ": #{context}"
    end
    super("Could not find a #{resource_name} using ID #{id}#{context}")
  end
end

