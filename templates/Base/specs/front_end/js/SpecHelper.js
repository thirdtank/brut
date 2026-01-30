import { createTestBasedOnHTML } from "brut-js/testing"

import path from "node:path"
import fs   from "node:fs"

const __dirname = import.meta.dirname

const appRoot               = path.resolve(__dirname,"..","..","..","app")
const publicRoot            = path.resolve(appRoot,"public")
const assetMetadataFilePath = path.resolve(appRoot,"config","asset_metadata.json")
const assetMetadata         = JSON.parse(fs.readFileSync(assetMetadataFilePath))

const withHTML = (html) => {
  return createTestBasedOnHTML({
    html,
    assetMetadata,
    publicRoot
  })
}

export {
  withHTML,
}

