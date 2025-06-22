import InputFile from "./InputFile.js"

export default class PseudoClassConfigFile extends InputFile {
  static field       = "pseudoClassConfig"
  static description = "Specialized .css describing the pseudo classes to support in the output"
  static shortField  = "p"

  static _handleNoValue() {
    return new PseudoClassConfigFile()
  }
}
