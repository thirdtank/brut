import CLIArgError from "./CLIArgError.js"
import ParsedArg   from "./ParsedArg.js"

export default class Debug extends ParsedArg {
  static field       = "debug"
  static description = "Show lots of output"
  static shortField  = "g"

  static toParseArgsOption() {
    return [
      this.longField,
      {
        type: "boolean",
        multiple: false,
        short: "g",
      }
    ]
  }

  static parse(values) {
    return new Debug(values[this.field])
  }
  constructor(debug) {
    super()
    this.debug = !!debug
  }
}
