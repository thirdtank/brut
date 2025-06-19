import postcss from "postcss"

const addMediaQueriesPlugin = (mediaQueries) => {
  return {
    postcssPlugin: 'add-media-queries',
    Once(root) {
      const toAppend = []
      mediaQueries.forEach( (mediaQuery) => {
        const atRule = mediaQuery.rawQuery ? postcss.atRule({ name: "media", params: mediaQuery.rawQuery }) : null
        root.walkRules( (rule) => {
          if (rule.selector !== ":root") {
            const cloned = rule.clone();
            if (mediaQuery.suffix) {
              cloned.selectors = cloned.selectors.map(sel => sel + `-${mediaQuery.suffix}`)
            }
            if (atRule) {
              atRule.append(cloned)
            }
            else {
              // No need to append - this rule is already there
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
addMediaQueriesPlugin.postcss = true
export default addMediaQueriesPlugin
