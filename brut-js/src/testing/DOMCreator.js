import { JSDOM, VirtualConsole } from "jsdom"

import AssetMetadataLoader from "./AssetMetadataLoader.js"

/**
 * Creates a JSDOM based on the the given HTML and query string.
 *
 * @memberof testing
 */
class DOMCreator {
  constructor(assetMetadata) {
    this.assetMetadata = assetMetadata
  }

  create({html,queryString}) {

    const resourceLoader = new AssetMetadataLoader(this.assetMetadata)


    const url = "http://example.com" + ( queryString ? `?${queryString}` : "" )

    const scripts = this.assetMetadata.scriptURLs().map( (url) => `<script src="${url}"></script>` )
    const virtualConsole = new VirtualConsole()
    virtualConsole.sendTo(console);
    return new JSDOM(
      `<!DOCTYPE html>
        <html>
        <head>
        ${scripts}
        </head>
        <body>
        ${html}
        </body>
        </html>
        `,{
          resources: "usable",
          runScripts: "dangerously",
          includeNodeLocations: true,
          resources: resourceLoader,
          url: url
        }
    )
  }
}
export default DOMCreator
