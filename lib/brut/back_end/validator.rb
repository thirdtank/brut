# Namespace for back-end validation support.  Note that in Brut, validators
# are not a mechanism for ensuring data integrity.  Validators are for helping
# a website visitor or app user to understand data entry mistakes.  To ensure
# data integrity, use your databases constraints and other features.
module Brut::BackEnd::Validators
  autoload(:FormValidator, "brut/back_end/validators/form_validator")
end
