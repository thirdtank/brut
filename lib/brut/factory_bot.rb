require "factory_bot"
require "faker"

# Encompasses a Brut app's FactoryBot configuration. This allows it to be used outside of tests.
class Brut::FactoryBot
  # Configures FactoryBot and finds all definitions.  After this, calls like `FactoryBot.create(...)` should work.
  def setup!
    Faker::Config.locale = :en
    FactoryBot.definition_file_paths = [
      Brut.container.app_specs_dir / "factories"
    ]
    FactoryBot.define do
      to_create { |instance| instance.save }
    end
    FactoryBot.find_definitions
  end
end
