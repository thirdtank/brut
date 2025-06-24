import Category from './Category.js'
export default class PropertyCategory extends Category {
  get ref() { return `property-category:${this.name}` }
}
