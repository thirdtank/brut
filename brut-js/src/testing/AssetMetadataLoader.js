import { ResourceLoader } from "jsdom"

/**
 * An JSDOM resource loader based on BrutRB asset metadata.
 *
 * @memberof testing
 */
class AssetMetadataLoader extends ResourceLoader {
  constructor(assetMetadata) {
    super()
    this.assetMetadata = assetMetadata
  }

  fetch(url,options) {
    const parsedURL = new URL(url)
    const jsContents = this.assetMetadata.fileContainingScriptURL(parsedURL.pathname)
    if (jsContents) {
      return Promise.resolve(jsContents)
    }
    else {
      return super.fetch(url,options)
    }
  }
}
export default AssetMetadataLoader
