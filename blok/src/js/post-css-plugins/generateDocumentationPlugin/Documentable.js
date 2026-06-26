export default class Documentable {
  constructor({name, description, sees, explicitTitle}) {
    this.name          = name
    this.description   = description
    this.sees          = sees || []
    this.explicitTitle = explicitTitle
  }
}
