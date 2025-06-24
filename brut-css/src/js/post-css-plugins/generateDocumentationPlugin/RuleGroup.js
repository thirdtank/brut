import Group from "./Group.js"
export default class RuleGroup extends Group {
  constructor({name, description, type, sees, explicitTitle}) {
    super({name, description, type, sees, explicitTitle})
    this.rules = []
    this.ref = `class-${type}:${name}`
  }
}
