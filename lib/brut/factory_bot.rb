# Because FactoryBot 6.4.6 has a bug where it is not properly
# requiring active support, active supporot must be required first,
# then factory bot.  When 6.4.7 is released, this can be removed. See Gemfile
require "active_support"
require "factory_bot"
require "faker"

class Brut::FactoryBot
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
