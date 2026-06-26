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
            let changedSelectors = false
            if (mediaQuery.suffix) {
              cloned.selectors = cloned.selectors.map( (selector) => {
                if ( selector.startsWith(".") && (selector.lastIndexOf(".") == 0) && selector.indexOf(" ") == -1 ) {
                  changedSelectors = true
                  if (selector.indexOf(":") == -1) {
                    return selector + `-${mediaQuery.suffix}`
                  }
                  else {
                    return selector.replace(/:(.*)$/, `-${mediaQuery.suffix}:$1`)
                  }
                }
                else {
                  return selector
                }
              })
            }
            if (atRule && changedSelectors) {
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
