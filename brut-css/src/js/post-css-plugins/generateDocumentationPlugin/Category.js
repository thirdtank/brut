import Documentable from "./Documentable.js"

class Category extends Documentable {
  constructor({name, description, sees}) {
    super({name, description, sees})
    this.scales = []
  }
}
export default Category
