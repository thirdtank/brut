# Allows manually triggering an exception so you can see
# the exception handling mechanism execute without waiting
# for a real exception to happen.
class TriggerExceptionHandler < AppHandler
  # These arguments are query string parameters that 
  # can be given to the URL connected to this handler.
  # See https://brutrb.com/keyword-injection.html for more details.
  def initialize(message: "no message provided", status: nil, key: nil)
    @message = message
    @status  = status
    @key     = key
  end

  def handle
    if @key != Brut.container.trigger_exception_key
      http_status(404)
    elsif @status
      http_status(@status)
    else
      raise @message
    end
  end
end

