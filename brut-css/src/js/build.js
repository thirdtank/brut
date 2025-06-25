import fs                                 from "node:fs"
import path                               from "node:path"
import postcss                            from "postcss"
import postcssImport                      from "postcss-import"

import Logger                             from "./Logger.js"
import generateRootCustomPropertiesPlugin from "./post-css-plugins/generateRootCustomPropertiesPlugin.js"
import addMediaQueriesPlugin              from "./post-css-plugins/addMediaQueriesPlugin.js"
import addPseudoClassesPlugin             from "./post-css-plugins/addPseudoClassesPlugin.js"
import generateDocumentationPlugin        from "./post-css-plugins/generateDocumentationPlugin.js"

import mediaQueryConfigParser             from "./mediaQueryConfigParser.js"
import pseudoClassConfigParser            from "./pseudoClassConfigParser.js"

import docGenerator                       from "./docGenerator.js"
import parseCLI                           from "./cli.js"

const generateCSS = ({
  input,
  output,
  mediaQueryConfig,
  pseudoClassConfig,
  docsDir,
  docsTemplateSourceDir,
  pathToBrutCSSRoot,
  debug,
}) => {

  Logger.instance = new Logger("build.js")
  if (debug.debug) {
    Logger.instance.level = "debug"
  }

  const inputCSS      = fs.readFileSync(input.filename, 'utf8')
  const mediaQueries  = mediaQueryConfigParser(mediaQueryConfig.filename)
  const pseudoClasses = pseudoClassConfigParser(pseudoClassConfig.filename)

  let error = false
  mediaQueries.forEach( (mediaQuery) => {
    if (mediaQuery.isError()) {
      error = true
      Logger.error(`Error with media query '${mediaQuery.rawQuery}': ${mediaQuery.error}`)
    }
  })
  pseudoClasses.forEach( (pseudoClass) => {
    if (pseudoClass.isError()) {
      error = true
      Logger.error(`Error with pseudo class '${pseudoClass.rule}': ${pseudoClass.error}`)
    }
  })
  if (error) {
    process.exit(1)
  }

  const postCSSPlugins = [
    postcssImport(),
    generateRootCustomPropertiesPlugin(),
  ]


  let parsedDocumentation = null
  if (docsDir.dirname) {
    if (!docsTemplateSourceDir.dirname) {
      Logger.error("You must provide docs-template-source-dir when supplying docs-dir")
      process.exit(1)
    }
    parsedDocumentation = {}
    postCSSPlugins.push(generateDocumentationPlugin(parsedDocumentation))
  }
  postCSSPlugins.push(addPseudoClassesPlugin(pseudoClasses))
  postCSSPlugins.push(addMediaQueriesPlugin(mediaQueries))


  postcss(postCSSPlugins).process(
    inputCSS, { from: input.filename }
  ).then( result => {
    const dirname = path.dirname(output.filename)
    if (!fs.existsSync(dirname)) {
      fs.mkdirSync(dirname, { recursive: true })
    }
    fs.writeFileSync(output.filename,result.css,"utf8")
    if (docsDir.dirname) {
      fs.mkdirSync(docsDir.dirname, { recursive: true })
      fs.readdirSync(docsDir.dirname).forEach( (relativePath) => {
        const fullPath = path.join(docsDir.dirname,relativePath)
        fs.rmSync(fullPath,{recursive: true})
      })
      docGenerator(docsDir.dirname, docsTemplateSourceDir.dirname, parsedDocumentation, pathToBrutCSSRoot.uri)
      Logger.log(`Docs generated in ${docsDir.dirname}`)
    }
    Logger.log(`CSS saved to ${output.filename}`)
  }).catch( (error) => {
    Logger.log("Error: %o", error)
    process.exit(1)
  })
}

const parseResult = parseCLI(process.argv)
if (parseResult.shouldExit()) {
  if (parseResult.isError()) {
    if (parseResult.errorMessage) {
      Logger.error(`Error: ${parseResult.errorMessage}`)
    }
    process.exit(1)
  }
  else {
    process.exit(0)
  }
}
generateCSS(parseResult.args)

