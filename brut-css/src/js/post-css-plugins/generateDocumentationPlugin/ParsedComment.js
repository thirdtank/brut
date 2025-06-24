import { parse as commentParser } from "comment-parser"
import SeeRef from "./SeeRef.js"
import SeeURL from "./SeeURL.js"

class ParsedComment {
  constructor(text) {
    const trimmed = (text || "").trim()
    const delimitersRemoved = trimmed.replace(/\/\*+/,"").replace(/\*+\//,"")
    this.normalizedComment = `/**\n ${delimitersRemoved}\n*/`
    this.parsedComment = commentParser(this.normalizedComment)
    if (this.parsedComment.length == 0) {
      throw `Was not given an actual comment: ${text}`
    }
    if (this.parsedComment.length > 1) {
      throw `Something is wrong: Got more than one comment from ${text}`
    }
    this.parsedComment = this.parsedComment[0]
  }

  get description() {
    return this.parsedComment.description
  }

  get isCategory() {
    return this.category.length > 0
  }

  get category() {
    const tags = this.parsedComment.tags
    const categoryTag = tags.find(tag => tag.tag === 'category')
    return categoryTag ? [ categoryTag.name, categoryTag.description ] : []
  }

  get isScaleOrGroup() {
    return this.scale.length > 0 || this.group.length > 0
  }

  get scale() {
    const tags = this.parsedComment.tags
    const scaleTag = tags.find(tag => tag.tag === 'scale')
    return scaleTag ? [ scaleTag.name, scaleTag.description ] : []
  }

  get group() {
    const tags = this.parsedComment.tags
    const groupTag = tags.find(tag => tag.tag === 'group')
    return groupTag ? [ groupTag.name, groupTag.description ] : []
  }

  get examples() {
    const tags = this.parsedComment.tags
    const exampleTags = tags.filter(tag => tag.tag === 'example')
    return exampleTags.map( (example) => {
      return { name: example.name, code: example.source.map( (x) => x.tokens.description ) } 
    })
  }
  get sees() {
    const tags = this.parsedComment.tags
    const seeTags = tags.filter(tag => tag.tag === 'see')
    return seeTags.map( (see) => {
      const ref = see.name
      const url = see.description
      if (!url) {
        return new SeeRef(ref)
      }
      else {
        return new SeeURL(ref, url)
      }
    })
  }

}
export default ParsedComment
