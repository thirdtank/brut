/** A wrapper around a string that provides useful utility functions
 * not present in the standard library.
 *
 * @example
 *
 * const string = RichString.fromString(element.textContent)
 * element.textContent = string.humanize().toString()
 */
class RichString {
  /** Prefer this over the constructor, as this will
   * wrap `possiblyDefinedStringOrRichString` only if necessary
   * as well as handle `null`.
   *
   * @param {null|undefined|String|RichString} possiblyDefinedStringOrRichString - if `null`, `undefined`, or otherwise falsey, this method returns `null`. If a String, returns a new `RichString` wrapping it. If a `RichString`, returns the `RichString` unchanged.
   */
  static fromString(possiblyDefinedStringOrRichString, {allowBlank=false} = {}) {
    if (possiblyDefinedStringOrRichString instanceof RichString) {
      return possiblyDefinedStringOrRichString
    }
    if (allowBlank && possiblyDefinedStringOrRichString === "") {
      return new RichString("")
    }
    if (!possiblyDefinedStringOrRichString) {
      return null
    }
    return new RichString(String(possiblyDefinedStringOrRichString))
  }

  /** Prefer `fromString` */
  constructor(string) {
    if (typeof string !== "string") {
      throw `You may only construct a RichString with a String, not a ${typeof string}`
    }
    this.string = string
  }

  /** Returns a `RichString` with the string capitalized. */
  capitalize() {
    return new RichString(this.string.charAt(0).toUpperCase() + this.string.slice(1))
  }

  /** Returns a `RichString` with the string un-capitalized. */
  decapitalize() {
    return new RichString(this.string.charAt(0).toLowerCase() + this.string.slice(1))
  }

  /** Returns a `RichString` with the string converted from snake or kebab case into camel case. */
  camelize() {
    // Taken from camelize npm module
    return RichString.fromString(this.string.replace(/[_.-](\w|$)/g, function (_, x) {
      return x.toUpperCase()
    }))
  }

  /** Returns a 'humanized' `RichString`, which is basically a de-camelized version with the first letter
   * capitalized.
   */
  humanize() {
    return this.decamlize({spacer: " "}).capitalize()
  }

  /** Returns a `RichString` with the string converted from camel case to snake or kebab case.
    *
    * @param {Object} parameters
    * @param {string} parameters.spacer ["_"] - a string to use when joining words together.
    *
    */
  decamlize({spacer="_"} = {}) {
    // Taken from decamelize NPM module

    // Checking the second character is done later on. Therefore process shorter strings here.
    if (this.string.length < 2) {
      return new RichString(this.string.toLowerCase())
    }

    const replacement = `$1${spacer}$2`

    // Split lowercase sequences followed by uppercase character.
    // `dataForUSACounties` → `data_For_USACounties`
    // `myURLstring → `my_URLstring`
    const decamelized = this.string.replace(
      /([\p{Lowercase_Letter}\d])(\p{Uppercase_Letter})/gu,
      replacement,
    )

    // Split multiple uppercase characters followed by one or more lowercase characters.
    // `my_URLstring` → `my_ur_lstring`
    return new RichString(decamelized.
      replace(
        /(\p{Uppercase_Letter})(\p{Uppercase_Letter}\p{Lowercase_Letter}+)/gu,
        replacement,
      ).
      toLowerCase()
    )
  }

  /** Return the underlying String value */
  toString() { return this.string }

  /** Return the underlying String value or null if the string is blank */
  toStringOrNull() {
    if (this.isBlank()) {
      return null
    }
    else {
      return this.string
    }
  }

  /* Returns true if this string has only whitespace in it */
  isBlank() {
    return this.string.trim() == ""
  }

}
export default RichString
