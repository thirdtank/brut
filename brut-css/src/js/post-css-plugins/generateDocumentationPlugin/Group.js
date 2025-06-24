import Documentable from "./Documentable.js"
export default class Group extends Documentable {
  constructor({name, description, type, sees, explicitTitle}) {
    super({name, description, sees, explicitTitle})
    this.type = type
  }
}
