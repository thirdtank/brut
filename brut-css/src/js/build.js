import fs                                 from "node:fs"
import postcss                            from "postcss"
import postcssImport                      from "postcss-import"

import generateRootCustomPropertiesPlugin from "./post-css-plugins/generateRootCustomPropertiesPlugin.js"
import addMediaQueriesPlugin              from "./post-css-plugins/addMediaQueriesPlugin.js"
import addPseudoClassesPlugin             from "./post-css-plugins/addPseudoClassesPlugin.js"
import generateDocumentationPlugin        from "./post-css-plugins/generateDocumentationPlugin.js"

import mediaQueryConfigParser             from "./mediaQueryConfigParser.js"
import pseudoClassConfigParser            from "./pseudoClassConfigParser.js"

import parseCLI                           from "./cli.js"

const generateCSS = ({input,output,mediaQueryConfig,pseudoClassConfig}) => {

  const inputCSS      = fs.readFileSync(input.filename, 'utf8')
  const mediaQueries  = mediaQueryConfigParser(mediaQueryConfig.filename)
  const pseudoClasses = pseudoClassConfigParser(pseudoClassConfig.filename)

  let error = false
  mediaQueries.forEach( (mediaQuery) => {
    if (mediaQuery.isError()) {
      error = true
      console.log(`Error with media query '${mediaQuery.rawQuery}': ${mediaQuery.error}`)
    }
  })
  pseudoClasses.forEach( (pseudoClass) => {
    if (pseudoClass.isError()) {
      error = true
      console.log(`Error with pseudo class '${pseudoClass.rule}': ${pseudoClass.error}`)
    }
  })
  if (error) {
    process.exit(1)
  }

  const postCSSPlugins = [
    postcssImport(),
    generateRootCustomPropertiesPlugin(),
  ]

  const parsedDocumentation = {}

  postCSSPlugins.push(generateDocumentationPlugin(parsedDocumentation))
  postCSSPlugins.push(addMediaQueriesPlugin(mediaQueries))
  postCSSPlugins.push(addPseudoClassesPlugin(pseudoClasses))


  postcss(postCSSPlugins).process(
    inputCSS, { from: input.filename }
  ).then( result => {
    fs.writeFileSync(output.filename,result.css,"utf8")
    fs.writeFileSync(output.filename + ".json",JSON.stringify(parsedDocumentation))
    console.log(`✅ CSS built to ${output.filename}`)
  })
}

const parseResult = parseCLI(process.argv)
if (parseResult.shouldExit()) {
  if (parseResult.isError()) {
    if (parseResult.errorMessage) {
      console.error(`❌ Error: ${parseResult.errorMessage}`)
    }
    process.exit(1)
  }
  else {
    process.exit(0)
  }
}
generateCSS(parseResult.args)

