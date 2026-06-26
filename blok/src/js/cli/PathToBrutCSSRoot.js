import ParsedArg   from "./ParsedArg.js"

export default class PathToBrutCSSRoot extends ParsedArg {
  static field       = "pathToBrutCSSRoot"
  static description = "Relative URI to where BrutCSS docs on brutrb.com will be"
  static shortField  = "r"

  static parse(values) {
    const uri = values[this.longField]
    return new this(uri)
  }
  constructor(uri) {
    super()
    this.uri = uri
  }
  static get longField() {
    return "path-to-brut-css-root"
  }
}
