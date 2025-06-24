export default class Documentable {
  constructor({name, description, sees}) {
    this.name        = name
    this.description = description
    this.sees        = sees || []
  }
}
