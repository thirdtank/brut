import Group from "./Group.js"
export default class PropertyGroup extends Group {
  constructor({name, description, type, sees}) {
    super({name, description, type, sees})
    this.properties = []
    this.ref = `property-${type}:${name}`
  }
}
