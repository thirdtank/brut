import fs          from "node:fs"
import CLIArgError from "./CLIArgError.js"
import ParsedArg   from "./ParsedArg.js"

export default class InputFile extends ParsedArg {
  static field       = "input"
  static description = "Input .css to process"
  static shortField  = "i"

  static parse(values) {
    const filename = values[this.longField]
    if (filename) {
      if (fs.existsSync(filename)) {
        return new this(filename)
      }
      else {
        return new CLIArgError(this.longField,`File '${filename}' does not exist`)
      }
    }
    else {
      return this._handleNoValue()
    }
  }
  constructor(filename) {
    super()
    this.filename = filename
  }
  static _handleNoValue() {
    return new CLIArgError(this.field,"is required")
  }
}
