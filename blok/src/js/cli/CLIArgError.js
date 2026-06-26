export default class CLIArgError {
  constructor(field,errorMessage) {
    this.field = field
    this.errorMessage = errorMessage
  }
  hasError() { return true }
}
