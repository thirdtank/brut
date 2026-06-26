import postcss from "postcss"
import Logger  from "../Logger.js"

const generateRootCustomPropertiesPlugin = () => {
  return {
    postcssPlugin: 'generate-root-properties',
    Once(root) {
      const rootVars = []
      let lastAtProperty = null
      root.walkAtRules("property", (atRule) => {
        const name = atRule.params.trim()
        let initialValue = null

        lastAtProperty = atRule

        atRule.walkDecls(decl => {
          if (decl.prop === 'initial-value') {
            initialValue = decl.value
          }
        })

        if (initialValue) {
          const decl = postcss.decl({ prop: name, value: initialValue })
          rootVars.push(decl)
        }
        else {
          Logger.warn(`No initial-value found for @property ${name}`)
        }

      })
      if (rootVars.length > 0) {
        const rootRule = postcss.rule({ selector: ':root' })
        rootVars.forEach(decl => rootRule.append(decl))
        if (lastAtProperty) {
          lastAtProperty.after(rootRule)
        }
        else {
          root.append(rootRule)
        }
      }
    }
  }
}
generateRootCustomPropertiesPlugin.postcss = true
export default generateRootCustomPropertiesPlugin
