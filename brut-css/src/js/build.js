import fs                              from "node:fs"
import postcss                         from "postcss"
import postcssImport                   from "postcss-import"
import mergeRootCustomPropertiesPlugin from "./mergeRootCustomPropertiesPlugin.js"
import parseCLI                        from "./cli.js"

const generateCSS = ({input,output}) => {

  try {
    const inputCSS = fs.readFileSync(input.filename, 'utf8')

    postcss(
      [
        postcssImport(),
        mergeRootCustomPropertiesPlugin()
      ]
    ).process(
      inputCSS, { from: input.filename }
    ).then( result => {
      fs.writeFileSync(output.filename, result.css, 'utf8')
    })
    console.log(`✅ CSS built to ${output.filename}`)
  } catch (err) {
    console.error(`❌ Error: ${err.message}`)
    process.exit(1)
  }
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

