# Indicates that a resource or database row does not exist.
class Brut::Framework::Errors::NotFound < Brut::Framework::Error
  def initialize(resource_name:,id:,context:nil)
    if !context.nil?
      context = ": #{context}"
    end
    super("Could not find a #{resource_name} using ID #{id}#{context}")
  end
end

