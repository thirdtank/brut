import fs          from "node:fs"
import CLIArgError from "./CLIArgError.js"
import ParsedArg   from "./ParsedArg.js"

export default class PseudoClassConfigFile extends ParsedArg {
  static field       = "pseudoClassConfig"
  static description = "Specialized .css describing the pseudo classes to support in the output"
  static shortField  = "p"

  static parse(values) {
    const filename = values[this.field]
    if (filename) {
      if (fs.existsSync(filename)) {
        return new PseudoClassConfigFile(filename)
      }
      else {
        return new CLIArgError(this.field,`File '${filename}' does not exist`)
      }
    }
    else {
      return new PseudoClassConfigFile()
    }
  }
  constructor(filename) {
    super()
    this.filename = filename
  }
}
