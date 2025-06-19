import postcss from "postcss"

const mergeRootCustomPropertiesPlugin = () => {
  return {
    postcssPlugin: 'merge-root-vars',
    Once(root) {
      const allRootDecls = []
      root.walkRules(':root', rule => {
        rule.walkDecls(decl => {
          if (decl.prop.startsWith('--')) {
            decl.raws.before = "\n  "
            allRootDecls.push(decl.clone())
          }
        })
        rule.remove()
      })

      if (allRootDecls.length > 0) {
        const newRoot = postcss.rule({ selector: ':root' })
        allRootDecls.forEach(decl => newRoot.append(decl))
        root.prepend(newRoot)
      }
    }
  }
}
mergeRootCustomPropertiesPlugin.postcss = true
export default mergeRootCustomPropertiesPlugin
