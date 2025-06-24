import Documentable from "./Documentable.js"
export default class Property extends Documentable {
  constructor({name, value, type, description, sees}) {
    super({name, description, sees})
    this.ref = name
    this.value = value
    this.type = type
  }
}
