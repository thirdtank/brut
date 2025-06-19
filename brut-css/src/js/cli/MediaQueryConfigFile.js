import fs          from "node:fs"
import CLIArgError from "./CLIArgError.js"
import ParsedArg   from "./ParsedArg.js"

export default class MediaQueryConfigFile extends ParsedArg {
  static field       = "mediaQueryConfig"
  static description = "Specialized .css describing the media queries to support in the output"
  static shortField  = "m"

  static parse(values) {
    const filename = values[this.field]
    if (filename) {
      if (fs.existsSync(filename)) {
        return new MediaQueryConfigFile(filename)
      }
      else {
        return new CLIArgError(this.field,`File '${filename}' does not exist`)
      }
    }
    else {
      return new MediaQueryConfigFile()
    }
  }
  constructor(filename) {
    super()
    this.filename = filename
  }
}
