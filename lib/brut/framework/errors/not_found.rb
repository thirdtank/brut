# Indicates that a resource or database row does not exist.
class Brut::Framework::Errors::NotFound < Brut::Framework::Error
  # @param [String] resource_name Name of the type of resource
  # @param [String|Int] id Identifier of the resource. If present, search_terms is ignored.
  # @param [Object] search_terms If provided, these are the search terms used. Will be converted to a string via `inspect`. Ignored if
  # id is present.
  # @param [String] context Any additional context about what went wrong
  def initialize(resource_name:,id: nil, search_terms: nil,context:nil)
    if !context.nil?
      context = ": #{context}"
    end
    fragment = if id.nil?
                 "Search '#{search_terms.inspect}'"
               else
                 "ID '#{id}'"
               end
    super("Could not find a #{resource_name} using #{fragment}#{context}")
  end
end

