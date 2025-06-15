import fs from "node:fs"
import path from "node:path"
/**
 * Provides structured access to the asset metadata for a BrutRB app. This is used to allow custom elements
 * to be defined in JSDOM the same way they are in a real browser.
 *
 * @memberof testing
 */
class AssetMetadata {
  constructor(parsedJSON, publicRoot) {
    this.assetMetadata = parsedJSON.asset_metadata
    this.publicRoot    = publicRoot
  }

  scriptURLs() {
    return Object.entries(this.assetMetadata[".js"]).map( (entry) => {
      return entry[0] 
    })
  }

  fileContainingScriptURL(scriptURL) {
    const file = Object.entries(this.assetMetadata[".js"]).find( (entry) => {
      return entry[0] == scriptURL
    })
    if (!file || !file[1]) {
      return null
    }
    let relativePath = file[1]
    if (relativePath[0] == "/") {
      relativePath = relativePath.slice(1)
    }
    return fs.readFileSync(path.resolve(this.publicRoot,relativePath))
  }
}
export default AssetMetadata
