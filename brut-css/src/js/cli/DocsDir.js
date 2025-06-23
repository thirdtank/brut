import ParsedArg   from "./ParsedArg.js"

export default class DocsDir extends ParsedArg {
  static field       = "docsDir"
  static description = "path to generate documentation"
  static shortField  = "d"

  static parse(values) {
    const dirname = values[this.longField]
    return new this(dirname)
  }
  constructor(dirname) {
    super()
    this.dirname = dirname
  }
}
