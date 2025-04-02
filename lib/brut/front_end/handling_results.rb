# Convienience methods to use inside handlers to make it easier to return richly typed results.
#
# @see Brut::FrontEnd::Handler
module Brut::FrontEnd::HandlingResults
  # Return this to cause your handler to redirect to `klass`' route with the given query string parameters.
  #
  # @param [Class] klass A page or handler class whose route should be redirected-to. Note that if parameters are required, they must
  # be provided in `query_string_params` or this will raise an error. Note that the class must be for a GET route, since you cannot
  # redirect to a non-GET.
  # @param [Hash] query_string_params arguments and parameters for the route.  Any values that correspond to route parameters will be used to build the route. A value of 'anchor' will be used as the hash/anchor part of the URL and should not contain a hash sign. Remaining will be used as query parameters.
  #
  # @raise [ArgumentError] if `klass` is not a `Class` or if `klass` is not for a `GET`
  # @raise [Brut::Framework::Errors::MissingParameter] if any required route parameters were not provided
  def redirect_to(klass, **query_string_params)
    if !klass.kind_of?(Class)
      raise ArgumentError,"redirect_to should be given a Class, not a #{klass.class}"
    end
    Brut.container.routing.path(klass,with_method: :get,**query_string_params)
  end

  # Return this to return an HTTP status code from a number or string containing the code.
  def http_status(number) = Brut::FrontEnd::HttpStatus.new(number)
end
