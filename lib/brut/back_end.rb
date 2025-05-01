# The _back end_ of a Brut app is where your app's business logic and database are managed.  While the bulk of your Brut app's code
# will be in the back end, Brut is far less prescriptive about how to manage that than it is the front end.
module Brut::BackEnd
  autoload(:Validators, "brut/back_end/validator")
  autoload(:Sidekiq, "brut/back_end/sidekiq")
  # Do not put SeedData here - it must be loaded only when needed
end
