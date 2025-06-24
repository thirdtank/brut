import Group from "./Group.js"
export default class RuleGroup extends Group {
  constructor({name, description, type, sees}) {
    super({name, description, type, sees})
    this.rules = []
    this.ref = `class-${type}:${name}`
  }
}
