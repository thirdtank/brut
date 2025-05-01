class Brut::FrontEnd::Layout < Brut::FrontEnd::Component
  def asset_path(path) = Brut.container.asset_path_resolver.resolve(path)
end
