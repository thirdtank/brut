# Brut Specs README

## Testing Philosophy

Brut is designed around classes that get instantiated and then methods are called.  Ideally there are
not tons of global state shared around to muck with basics of object-oriented programming.

Brut also does not need to be used to test itself. 

* Brut's tests should test behavior, not implementation.  
* Private methods should never ever be tested.
* Use of `instance_variable_set` and the like is a smell and to be avoided.  If a related class needs to be mucked with, that class can be enhanced to avoid monkeypatching and metaprogramming.
* Avoid using doubles for Brut's classes if they can be instantiated and passed as arguments to a
constructor method. Brut's classes are designed to be created easily


## Brut.container

Never use a double as the container. Use a real `Brut::Framework::Container` and stub `Brut.container` to return it. Tests fall into three categories:

* **No container needed**: don't set one up.
* **Needs specific values**: `store` only those values on a real container. Values like `instrumentation` may be test doubles.
* **Needs real configuration**: use a tmp project directory, store `project_root`, call `Brut::Framework::Config.new(container:).configure!`, and override values only when necessary.

Use `before`/`after` blocks for container setup. Do not add yielding `with_xxx` helpers.


## Rspec

Brut uses RSpec but only part of RSpec.

### Not Allowed

* NO Shared contexts
* NO Shared examples
* NO predicate matchers, even `be_nil` and `be_empty` (just call the methods directly in the test)
* Test for "truthy" or "falsey" - test for the actual values

### Strongly Avoid

* Excessive use of `let` or `let!` - these are not ways to define methods and generally all test
  setup should be in the test itself.  If something is needed for EVERY test, putting it in a `let`
  makes sense, or if the value is some test data that is the same within a context, that's fine.
  But use of let and then overriding it in a context is to be avoided
* Running the code in a let or before and then having a ton of single-line assertions. Just make one
  test with all the assertions.

### Confidence Checks
  
The use of `confidence_check` is *not* for testing. It's for asserting that any test setup or other
invariants unrelated to the test hold. It should not be needed often, and any test that is just a
confidence check is wrong.
