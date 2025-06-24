import Documentable from "./Documentable.js"
export default class Group extends Documentable {
  constructor({name, description, type, sees}) {
    super({name, description, sees})
    this.type = type
  }
}
