export default class ParsedArg {
  hasError() { return false }
  static isArray() { return false }
  static toParseArgsOption() {
    return [
      this.field,
      {
        type: "string",
        multiple: this.isArray(),
        short: this.shortField,
      }
    ]
  }
}
