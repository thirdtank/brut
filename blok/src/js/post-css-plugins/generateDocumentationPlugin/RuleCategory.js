import Category from './Category.js'
export default class RuleCategory extends Category {
  get ref() { return `class-category:${this.name}` }
}
