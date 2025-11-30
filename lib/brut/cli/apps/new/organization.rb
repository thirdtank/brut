class Brut::CLI::Apps::New::Organization < Brut::CLI::Apps::New::InternetIdentifier
  def initialize(value)
    super(:organization, value)
  end
end
