import Group from "./Group.js"
export default class PropertyGroup extends Group {
  constructor({name, description, type, sees, explicitTitle}) {
    super({name, description, type, sees, explicitTitle})
    this.properties = []
    this.ref = `property-${type}:${name}`
  }
}
