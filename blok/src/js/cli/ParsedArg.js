export default class ParsedArg {
  hasError() { return false }
  static isArray() { return false }
  static toParseArgsOption() {
    return [
      this.longField,
      {
        type: "string",
        multiple: this.isArray(),
        short: this.shortField,
      }
    ]
  }
  static get longField() {
    return this.field.replace(/([A-Z])/g, '-$1').toLowerCase()
  }
}
