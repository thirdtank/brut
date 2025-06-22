import InputFile   from "./InputFile.js"

export default class MediaQueryConfigFile extends InputFile {
  static field       = "mediaQueryConfig"
  static description = "Specialized .css describing the media queries to support in the output"
  static shortField  = "m"
  static _handleNoValue() {
    return new MediaQueryConfigFile()
  }
}
