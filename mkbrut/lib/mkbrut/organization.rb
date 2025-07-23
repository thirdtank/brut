class MKBrut::Organization < MKBrut::InternetIdentifier
  def initialize(value)
    super(:organization, value)
  end
end
