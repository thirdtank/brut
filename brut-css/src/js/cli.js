import { parseArgs }         from "node:util"
import InputFile             from "./cli/InputFile.js"
import MediaQueryConfigFile  from "./cli/MediaQueryConfigFile.js"
import PseudoClassConfigFile from "./cli/PseudoClassConfigFile.js"
import OutputFile            from "./cli/OutputFile.js"

const cliArgs = [
  InputFile,
  MediaQueryConfigFile,
  PseudoClassConfigFile,
  OutputFile,
]

const parseArgsOptions = Object.fromEntries(cliArgs.map( (argClass) => argClass.toParseArgsOption() ))

const showHelp = () => {
  console.log("usage: build.js [options]")
  console.log()
  console.log("OPTIONS")
  console.log()
  cliArgs.forEach( (argClass) => {
    console.log("  -%s/%s - %s",argClass.shortField,`--${argClass.field}`.padEnd(18),argClass.description)
    if (argClass.isArray()) {
      console.log("                          [use multiple times for mulitple values]")
    }
  })
}

class ParseResult {
  constructor(parsedArgs) {
    this.args = parsedArgs
  }
  shouldExit() { return false }
  isError() { return false }
}

class ExitParseResult extends ParseResult {
  constructor() {
    super({})
  }
  shouldExit() { return true }
  isError() { return false }
}
class ErrorParseResult extends ExitParseResult {
  constructor(errorMessage) {
    super()
    this.errorMessage = errorMessage
  }
  isError() { return true }
}

const parseCLI = (argv) => {
  const firstArg = argv[2]

  if ( !firstArg             ||
    firstArg == "--help" ||
    firstArg == "-h"     ||
    firstArg == "-help"  ||
    firstArg == "help" ) {

    showHelp()
    return new ExitParseResult()
  }

  try {
  const args = process.argv.slice(2)
  const {
    values,
    positionals
  } = parseArgs({
    args: args,
    options: parseArgsOptions,
    strict: true,
  })

  const parsedValues = cliArgs.map( (klass) => klass.parse(values) )

  const errors = parsedValues.filter( (pv) => pv.hasError() )

  if (errors.length > 0) {
    console.log("%d %s in command-line arguments:",errors.length,errors.length == 1 ? "error" : "errors")
    console.log()
    errors.forEach( (error) => {
      console.log("  --%s - %s",error.field.padEnd(18),error.errorMessage)
    })
    return new ErrorParseResult()
  }

  return new ParseResult(Object.fromEntries(parsedValues.map( (pv) => [ pv.constructor.field,pv] )))
  }
  catch (error) {
    return new ErrorParseResult(error.message)
  }
}
export default parseCLI
