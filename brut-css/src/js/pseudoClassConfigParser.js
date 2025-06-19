import fs        from "node:fs"
import postcss   from "postcss"

class PseudoClass {
  constructor(pseudoClass, prefix, extra, classRules) {
    this.pseudoClass = pseudoClass
    this.prefix      = prefix
    this.extra       = extra
    this.classRules  = classRules
    this.error       = null
    this.rule        = null
  }
  isError() { return false }

  surroundAtRule() {
    if ( (this.pseudoClass == "hover") && (this.extra == "true") ) {
      return { name: "media", params: "(hover: hover)" }
    }
    return null
  }
  includesSelector(selector) {
    if (this.#exactlyOneDot(selector)) {
      return this.classRules.some( (classRule) => classRule.includesSelector(selector) )
    }
    else {
      return false
    }
  }

  #exactlyOneDot(selector) {
    return selector.startsWith(".") && (selector.lastIndexOf(".") == 0)
  }
}
class ParseError {
  constructor(rule, error) {
    this.rule  = rule
    this.error = error
  }
  isError() { return true }
}

class ColorsClassRule {
  static COLORS = [
    "red",
    "orange",
    "yellow",
    "green",
    "blue",
    "purple",
    "gray",
    "black",
    "white",
  ]

  includesSelector(selector) {
    return ColorsClassRule.COLORS.some( (color) => selector.startsWith(`.${color}-`) )
  }
}

class PrefixedClassRule {
  constructor(prefix) {
    this.prefix = prefix
  }
  includesSelector(selector) {
    return selector.startsWith(`.${this.prefix}`)
  }
}
class SpecificClassRule {
  constructor(className) {
    this.selector = `.${className}`
  }
  includesSelector(selector) {
    return selector === this.selector
  }
}

class AtRuleParenExpression {
  constructor(params) {
    this.value = params.trim().replace(/^\(\s*/,"").replace(/\s*\)$/,"")
  }
  isEmpty() {
    return this.value.length == 0
  }
}

const pseudoClassConfigParser = (pseudoClassConfigFile) => {
  const pseudoClasses = [
  ]

  if (!pseudoClassConfigFile) {
    return pseudoClasses
  }

  const css = fs.readFileSync(pseudoClassConfigFile, 'utf8')
  const parsedCSS = postcss.parse(css, { from: pseudoClassConfigFile })

  parsedCSS.walkAtRules("brut-pseudo", (rule) => {
    const [pseudoClass,prefix,extra] = new AtRuleParenExpression(rule.params).value.split(/\s+/)
    if (!pseudoClass) {
      pseudoClasses.push(new ParseError(rule, "@brut-pseudo requires an '(-expression)' of pseudo-class and prefix"))
    }
    else if (!prefix) {
      pseudoClasses.push(new ParseError(rule, "@brut-pseudo found a pseudo-class, but no prefix"))
    }
    else {
      const classRules = []
      rule.walkAtRules( (innerRule) => {
        if (innerRule.name == "brut-class") {
          const params = new AtRuleParenExpression(innerRule.params)
          if (params.isEmpty()) {
            pseudoClasses.push(new ParseError(rule, "@brut-class must contain a CSS class name"))
          }
          else {
            classRules.push(new SpecificClassRule(params.value))
          }
        }
        else if (innerRule.name == "brut-classes-with-prefix") {
          const params = new AtRuleParenExpression(innerRule.params)
          if (params.isEmpty()) {
            pseudoClasses.push(new ParseError(rule, "@brut-classes-with-prefix must contain a CSS class name prefix"))
          }
          else {
            classRules.push(new PrefixedClassRule(params.value))
          }
        }
        else if (innerRule.name == "brut-colors") {
          classRules.push(new ColorsClassRule())
        }
        else {
          console.warn(":@brut-pseudo contains an unknown at-rule", innerRule.name, "ignoring it")
        }
      })
      if (classRules.length == 0) {
        pseudoClasses.push(new ParseError(rule, "@brut-pseudo requires at least one @brut-class, @brut-classes-with-prefix or @brut-colors rule"))
      }
      else {
        pseudoClasses.push(new PseudoClass(pseudoClass, prefix, extra, classRules))
      }
    }
  })
  return pseudoClasses
}

export default pseudoClassConfigParser
