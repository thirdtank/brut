import Property         from "./Property.js"
import PropertyCategory from "./PropertyCategory.js"
import PropertyGroup    from "./PropertyGroup.js"
import Rule             from "./Rule.js"
import RuleCategory     from "./RuleCategory.js"
import RuleGroup        from "./RuleGroup.js"
import selectorParser   from "postcss-selector-parser"

class Selectors {
  constructor(selectorString) {
    this.selectors = [];

    selectorParser(selectorsAST => {
      selectorsAST.each(selector => {
        this.selectors.push(selector.toString().trim());
      });
    }).processSync(selectorString);
  }
  forEach(callback) {
    this.selectors.forEach(callback);
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
    this.refs = {}
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
      this.currentCategory = new PropertyCategory({
        name: parsedComment.category[0],
        explicitTitle: parsedComment.category[1],
        description: parsedComment.description,
        sees: parsedComment.sees,
      })
    }
    else {
      this.insideRules = true
      if (this.currentCategory) {
        this.classCategories.push(this.currentCategory)
      }
      this.currentCategory = new RuleCategory({
        name: parsedComment.category[0],
        explicitTitle: parsedComment.category[1],
        description: parsedComment.description,
        sees: parsedComment.sees,
      })
    }
    this.refs[this.currentCategory.ref] = this.currentCategory
    this.insideCategory = true
    this.insideScale = false
  }

  newScale(parsedComment) {
    if (this.insideProperties || this.insideRules) {
      if (!this.currentCategory) {
        console.log(parsedComment)
        throw this.root.error(`Something is wrong - no current category: ${parsedComment}`)
      }
      const groupAttributes = {
        description: parsedComment.description,
        sees: parsedComment.sees,
      }
      if (parsedComment.scale.length != 0) {
        groupAttributes.name = parsedComment.scale[0]
        groupAttributes.explicitTitle = parsedComment.scale[1]
        groupAttributes.type = "scale"
      }
      else {
        groupAttributes.name = parsedComment.group[0]
        groupAttributes.explicitTitle = parsedComment.group[1]
        groupAttributes.type = "group"
      }
      if (this.insideProperties) {
        this.currentScale = new PropertyGroup(groupAttributes)
      }
      else if (this.insideRules) {
        this.currentScale = new RuleGroup(groupAttributes)
      }
      this.refs[this.currentScale.ref] = this.currentScale
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
      throw this.root.error(`While parsing comments from @property definitions, encountered a comment without an @category. The comments inside the @property blocks must begin with a comment with the @category tag: ${parsedComment.normalizedComment}`)
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

    const property = new Property({
      name: node.params.trim(),
      value: initialValue,
      type: syntax,
      description: this.comment ? this.comment.description : null,
      sees: this.comment ? this.comment.sees : null,
    })
    this.currentScale.properties.push(property)
    this.refs[property.ref] = property
    this.commentStack = null
  }
  pushRule(node) {
    const selectors = new Selectors(node.selector)
    selectors.forEach( (selector) => {
      const rule = new Rule({
        selector: selector,
        description: this.comment ? this.comment.description : null,
        examples: this.comment ? this.comment.examples : [],
        sees: this.comment ? this.comment.sees : null,
      })
      this.currentScale.rules.push(rule)
      this.refs[rule.ref] = rule
    })
    this.comment = null
  }
  done() {
    if (this.currentCategory) {
      this.classCategories.push(this.currentCategory)
      this.currentCategory = null
    }
  }
}

export default DocState
