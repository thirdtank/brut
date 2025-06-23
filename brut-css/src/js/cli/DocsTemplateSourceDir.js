import ParsedArg   from "./ParsedArg.js"

export default class DocsTemplateSourceDir extends ParsedArg {
  static field       = "docsTemplateSourceDir"
  static description = "path where doc templates live"
  static shortField  = "t"

  static parse(values) {
    const dirname = values[this.longField]
    return new this(dirname)
  }
  constructor(dirname) {
    super()
    this.dirname = dirname
  }
}
