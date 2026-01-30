class Bootstrap

  def configure_only!
    self
  end

  attr_reader :rack_app, :app

  def bootstrap!
    self.configure_only!
    self
  end

end
