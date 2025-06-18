import fs          from "node:fs"
import CLIArgError from "./CLIArgError.js"
import ParsedArg   from "./ParsedArg.js"

export default class InputFile extends ParsedArg {
  static field       = "input"
  static description = "Input .css to process"
  static shortField  = "i"

  static parse(values) {
    const filename = values[this.field]
    if (filename) {
      if (fs.existsSync(filename)) {
        return new InputFile(filename)
      }
      else {
        return new CLIArgError(this.field,`File '${filename}' does not exist`)
      }
    }
    else {
      return new CLIArgError(this.field,"is required")
    }
  }
  constructor(filename) {
    super()
    this.filename = filename
  }
}
