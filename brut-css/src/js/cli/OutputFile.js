import CLIArgError from "./CLIArgError.js"
import ParsedArg   from "./ParsedArg.js"

export default class OutputFile extends ParsedArg {
  static field       = "output"
  static description = "Output .css (this is what your app will use)"
  static shortField  = "o"

  static parse(values) {
    const filename = values[this.field]
    if (filename) {
      return new OutputFile(filename)
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
