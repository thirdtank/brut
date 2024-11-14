require "rexml"

# Produces `<brut-i18n-translation>` entries for the given values
class Brut::FrontEnd::Components::I18nTranslations < Brut::FrontEnd::Component
  def initialize(i18n_key_root)
    @i18n_key_root = i18n_key_root
  end

  def render
    values = ::I18n.t(@i18n_key_root)
    if values.kind_of?(String)
      values = { "" => values }
    end

    values.map { |key,value|
      if !value.kind_of?(String)
        raise "Key #{key} under #{@i18n_key_root} maps to a #{value.class} instead of a String. For #{self.class} to work, the value must be a String"
      end
      i18n_key = if key == ""
                   @i18n_key_root
                 else
                   "#{@i18n_key_root}.#{key}"
                 end
      attributes = [
        REXML::Attribute.new("key",i18n_key),
        REXML::Attribute.new("value",value.to_s),
      ]
      if !Brut.container.project_env.production?
        attributes << REXML::Attribute.new("show-warnings",true)
        attributes << REXML::Attribute.new("id","brut-18n-#{key}")
      end
      attribute_string = attributes.map(&:to_string).join(" ")
      %{<brut-i18n-translation #{attribute_string}></brut-i18n-translation>}
    }.join("\n")
  end
end
