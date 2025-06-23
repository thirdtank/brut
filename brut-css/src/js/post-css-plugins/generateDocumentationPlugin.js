import markdownit from "markdown-it"

import { parse as commentParser } from "comment-parser"

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

  get category() {
    const tags = this.parsedComment.tags
    const categoryTag = tags.find(tag => tag.tag === 'category')
    return categoryTag ? categoryTag.name : null
  }

  get scale() {
    const tags = this.parsedComment.tags
    const scaleTag = tags.find(tag => tag.tag === 'scale')
    return scaleTag ? scaleTag.name : null
  }

  get group() {
    const tags = this.parsedComment.tags
    const scaleTag = tags.find(tag => tag.tag === 'group')
    return scaleTag ? scaleTag.name : null
  }

  get examples() {
    const tags = this.parsedComment.tags
    const exampleTags = tags.filter(tag => tag.tag === 'example')
    return exampleTags.map( (example) => {
      return { name: example.name, code: example.source.map( (x) => x.tokens.description ) } 
    })
  }

}
class DocState {
  constructor(root) {
    this.root = root
    this.comment = null
    this.propertyCategories = []
    this.classCategories = []
    this.insidePropertiesSection = false
    this.insideRulesSection = false
  }

  get insideProperties() {
    return this.insidePropertiesSection
  }

  set insideProperties(value) {
    this.insidePropertiesSection = value
    if (!value) {
      if (this.currentCategory) {
        this.propertyCategories.push(this.currentCategory)
      }
      this.currentCategory = null
      this.currentScale = null
    }
  }

  get insideRules() {
    return this.insideRulesSection
  }

  set insideRules(value) {
    if (value && this.insideProperties) {
      console.log("inside rules now")
      this.insideProperties = false
    }
    this.insideRulesSection = value
  }

  newCategory(parsedComment) {
    if (this.insideProperties) {
      if (this.currentCategory) {
        this.propertyCategories.push(this.currentCategory)
      }
      this.currentCategory = new PropertyCategory(
        parsedComment.category,
        parsedComment.description
      )
    }
    else {
      this.insideRules = true
      if (this.currentCategory) {
        this.classCategories.push(this.currentCategory)
      }
      this.currentCategory = new RuleCategory(
        parsedComment.category,
        parsedComment.description
      )
    }
    this.insideCategory = true
    this.insideScale = false
  }

  newScale(parsedComment) {
    if (this.insideProperties || this.insideRules) {
      if (!this.currentCategory) {
        console.log(parsedComment)
        throw this.root.error(`Something is wrong - no current category: ${parsedComment}`)
      }
      if (this.insideProperties) {
        this.currentScale = new PropertyGroup(
          parsedComment.scale || parsedComment.group,
          parsedComment.description,
          parsedComment.scale ? "scale" : "group",
        )
      }
      else if (this.insideRules) {
        this.currentScale = new RuleGroup(
          parsedComment.scale || parsedComment.group,
          parsedComment.description,
          parsedComment.scale ? "scale" : "group",
        )
      }
      this.currentCategory.scales.push(this.currentScale)
      this.insideScale = true
    }
    else {
      throw this.root.error(`@scale may not be defined outside a @category`)
    }
  }

  pushComment(parsedComment) {
    if (this.insideScale) {
      this.comment = parsedComment
    }
    else if (this.insideCategory) {
      throw this.root.error(`Inside a category, the next comment must establish a scale`)
    }
    else {
      throw this.root.error(`While parsing comments from @property definitions, encountered a comment without an @category. The comments inside the @property blocks must begine with a comment with the @category tag: ${parsedComment.normalizedComment}`)
    }
  }
  pushProperty(node) {
    let initialValue = null
    let syntax = null
    node.walkDecls(decl => {
      if (decl.prop === 'initial-value') {
        initialValue = decl.value
      }
      if (decl.prop === 'syntax') {
        syntax = decl.value
      }
    })

    this.currentScale.properties.push(new Property(
      node.params.trim(),
      initialValue,
      syntax,
      this.comment ? this.comment.description : null
    ))
    this.commentStack = null
  }
  pushRule(node) {
    this.currentScale.rules.push(new Rule(
      node.selector,
      this.comment ? this.comment.description : null,
      this.comment ? this.comment.examples : [],
    ))
    this.comment = null
  }
  done() {
    if (this.currentCategory) {
      this.classCategories.push(this.currentCategory)
      this.currentCategory = null
    }
  }
}

class Category {
  constructor(name, description) {
    this.name = name
    this.description = description
    this.scales = []
  }
  get title() {
    return this.name.charAt(0).toUpperCase() + this.name.slice(1)
  }

  get descriptionHTML() {
    const markdown = new markdownit({
      html: true,
      linkify: true,
      typographer: true,
    })
    return markdown.render(this.description)
  }
}
class RuleCategory extends Category {}
class PropertyCategory extends Category {}

class Group {
  constructor(name, description, type) {
    this.name = name
    this.description = description
    this.type = type
  }
  get title() {
    return this.name.charAt(0).toUpperCase() + this.name.slice(1)
  }
  get descriptionHTML() {
    const markdown = new markdownit({
      html: true,
      linkify: true,
      typographer: true,
    })
    return markdown.render(this.description)
  }
}

class PropertyGroup extends Group {
  constructor(name, description, type) {
    super(name, description, type)
    this.properties = []
  }
}

class RuleGroup extends Group {
  constructor(name, description, type) {
    super(name, description, type)
    this.rules = []
  }
}

class Property {
  constructor(name, value, type, description) {
    this.name = name
    this.value = value
    this.type = type
    this.description = description
  }
  get descriptionHTML() {
    const markdown = new markdownit({
      html: true,
      linkify: true,
      typographer: true,
    })
    return markdown.render(this.description)
  }
}
class Rule {
  constructor(selector, description, examples, code) {
    this.selector = selector
    this.description = description
    this.examples = examples
    this.code = code
  }
  get descriptionHTML() {
    if (this.description) {
      const markdown = new markdownit({
        html: true,
        linkify: true,
        typographer: true,
      })
      return markdown.render(this.description)
    }
    else {
      return ""
    }
  }
}

const generateDocumentationPlugin = (parsedDocumentation) => {
  return {
    postcssPlugin: 'generate-documentation',
    Once(root) {
      let state = new DocState(root)
      state.insideProperties = true // Assume @property values preceed all others
      root.walk(node => {
        if (node.type === 'comment') {
          const parsedComment = new ParsedComment(node.text)
          if (parsedComment.category) {
            state.newCategory(parsedComment)
          }
          else if ( (parsedComment.scale) || (parsedComment.group) ) {
            state.newScale(parsedComment)
          }
          else {
            state.pushComment(parsedComment)
          }
        }

        else if (node.type === 'atrule' && node.name === 'property') {
          state.pushProperty(node)
        }

        else if (node.type === 'rule' && node.selector === ':root') {
          state.insideProperties = false
        }

        else if (node.type === 'rule') {
          state.insideRules = true
          state.pushRule(node)
        }
        else {
        }
      })
      state.done()
      parsedDocumentation.propertyCategories = state.propertyCategories
      parsedDocumentation.classCategories = state.classCategories.filter( (category) => {
        return category.name != "reset"
      })
    }
  }
}
generateDocumentationPlugin.postcss = true
export default generateDocumentationPlugin
