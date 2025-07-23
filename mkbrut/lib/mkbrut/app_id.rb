class MKBrut::AppId < MKBrut::InternetIdentifier
  def self.from_app_name(app_name)
    self.new(app_name.to_s.gsub(/[^a-zA-Z0-9\-]/, "-").downcase)
  end
  def initialize(value)
    super(:app_id, value)
  end
end
