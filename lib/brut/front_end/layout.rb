# A layout is common HTML that surrounds different pages. For example, it would hold your 
# DOCTYPE, `<head>`, and possibly any common `<body>` elements that every page needs. 
#
# A layout is a Phlex component but it must contain a call to `yield` somewhere in the 
# implementation of `view_template`.
#
# This base class contains helper methods needed for implementing a layout.
class Brut::FrontEnd::Layout < Brut::FrontEnd::Component
  # Get the actual path of an asset managed by Brut. This handles
  # locating the asset's URL as well as ensuring the hash is properly
  # inserted into the filename.
  #
  # @param [String] path the path to an asset, such as `/css/styles.css`.
  #
  # @return [String] the actual path to the current version of that asset.
  #
  # @see Brut::FrontEnd::AssetPathResolver
  def asset_path(path) = Brut.container.asset_path_resolver.resolve(path)
end
