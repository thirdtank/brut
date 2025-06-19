import fs                              from "node:fs"
import postcss                         from "postcss"
import postcssImport                   from "postcss-import"
import mergeRootCustomPropertiesPlugin from "./mergeRootCustomPropertiesPlugin.js"
import addMediaQueriesPlugin           from "./addMediaQueriesPlugin.js"
import parseCLI                        from "./cli.js"
import mediaQueryConfigParser          from "./mediaQueryConfigParser.js"

const generateCSS = ({input,output,mediaQueryConfig}) => {

  const inputCSS = fs.readFileSync(input.filename, 'utf8')
  const mediaQueries = mediaQueryConfigParser(mediaQueryConfig.filename)
  let error = false
  mediaQueries.forEach( (mediaQuery) => {
    if (mediaQuery.isError()) {
      error = true
      console.log(`Error with media query '${mediaQuery.rawQuery}': ${mediaQuery.error}`)
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

