import ParsedComment from "./generateDocumentationPlugin/ParsedComment.js"
import DocState from "./generateDocumentationPlugin/DocState.js"

const generateDocumentationPlugin = (parsedDocumentation) => {
  return {
    postcssPlugin: 'generate-documentation',
    Once(root) {
      let state = new DocState(root)
      state.insideProperties = true // Assume @property values preceed all others
      root.walk(node => {
        if (node.type === 'comment') {
          const parsedComment = new ParsedComment(node.text)
          if (parsedComment.isCategory) {
            state.newCategory(parsedComment)
          }
          else if ( parsedComment.isScaleOrGroup ) {
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
      parsedDocumentation.refs = state.refs
    }
  }
}
generateDocumentationPlugin.postcss = true
export default generateDocumentationPlugin
