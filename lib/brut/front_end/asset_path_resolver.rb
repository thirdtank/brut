class Brut::FrontEnd::AssetPathResolver
  def initialize(metadata_file:)
    @metadata_file = metadata_file
    reload
  end

  def reload
    @asset_metadata = Brut::FrontEnd::AssetMetadata.new(asset_metadata_file: @metadata_file)
    @asset_metadata.load!
  end

  def resolve(path)
    @asset_metadata.resolve(path)
  end
end
