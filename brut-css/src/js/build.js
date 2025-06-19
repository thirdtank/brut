import fs                              from "node:fs"
import postcss                         from "postcss"
import postcssImport                   from "postcss-import"
import mergeRootCustomPropertiesPlugin from "./post-css-plugins/mergeRootCustomPropertiesPlugin.js"
import addMediaQueriesPlugin           from "./post-css-plugins/addMediaQueriesPlugin.js"
import addPseudoClassesPlugin          from "./post-css-plugins/addPseudoClassesPlugin.js"
import parseCLI                        from "./cli.js"
import mediaQueryConfigParser          from "./mediaQueryConfigParser.js"
import pseudoClassConfigParser         from "./pseudoClassConfigParser.js"

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

  postcss(
    [
      postcssImport(),
      mergeRootCustomPropertiesPlugin(),
      addMediaQueriesPlugin(mediaQueries),
      addPseudoClassesPlugin(pseudoClasses),
    ]
  ).process(
    inputCSS, { from: input.filename }
  ).then( result => {
    fs.writeFileSync(output.filename,result.css,"utf8")
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

