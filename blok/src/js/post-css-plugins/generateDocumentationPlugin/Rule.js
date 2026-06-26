import Documentable from "./Documentable.js"

export default class Rule extends Documentable {
  constructor({selector, description, examples, code, sees}) {
    super({name: selector.replace(/^\./, ''), description, sees})
    this.selector = selector
    this.ref = this.name
    this.description = description
    this.examples = examples
    this.code = code
  }
}
