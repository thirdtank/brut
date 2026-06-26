import postcss from "postcss"

const addPseudoClassesPlugin = (pseudoClasses) => {
  return {
    postcssPlugin: 'add-pseudo-classes',
    Once(root) {
      const toAppend = []
      pseudoClasses.forEach( (pseudoClass) => {
        const atRule = pseudoClass.surroundAtRule() ? postcss.atRule(pseudoClass.surroundAtRule()) : null
        root.walkRules( (rule) => {
          if (rule.selector !== ":root") {
            if (pseudoClass.includesSelector(rule.selector)) {
              const cloned = rule.clone();
              cloned.selectors = cloned.selectors.map(sel => {
                if (sel.startsWith(".")) {
                  return `.${pseudoClass.prefix}-` + sel.slice(1) + `:${pseudoClass.pseudoClass}`
                }
                else {
                  return sel
                }
              })
              if (atRule) {
                atRule.append(cloned)
              }
              else {
                toAppend.push(cloned)
              }
            }
          }
        })
        if (atRule) {
          toAppend.push(atRule)
        }
      })
      toAppend.forEach( (rule) => {
        root.append(rule)
      })
    }
  }
}
addPseudoClassesPlugin.postcss = true
export default addPseudoClassesPlugin
