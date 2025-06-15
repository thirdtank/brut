/**
 * Abstract interface for logging information from a component.
 * This is intended to allow prefixed messages to be optionally shown
 * in the console to help debug.
 *
 * @see BufferedLogger
 * @see PrefixedLogger
 * @see BaseCustomElement#logger
 */
class Logger {
  /** Create a logger for the given prefix.
   *
   * @param {string|false} stringOrFalse - if false,returns a {@link BufferedLogger}. Otherwise, returns a {@link PrefixedLogger} using the param's value as the prefix.
   *
   * @returns {Logger}
   */
  static forPrefix(stringOrFalse) {
    if (!stringOrFalse) {
      return new BufferedLogger()
    }
    else {
      return new PrefixedLogger(stringOrFalse)
    }
  }

  /** Subclasses must implement this.
   *
   * @param {string} level - 'info' or 'warn' to indicate the logging level
   * @param {...*} args - args to pass directly to console.log
   */
  log() {
    throw `Subclass must implement`
  }

  /** Log an informational bit of information */
  info(...args) { this.log("info",...args) }
  /** Log a warning */
  warn(...args) { this.log("warn",...args) }
}

/** Logger that buffers, but does not print, its logged messages.
 * The reason it buffers them is to allow custom elements to retroatively log
 * information captured before warnings were turned on.
 */
class BufferedLogger extends Logger {
  constructor() {
    super()
    this.messages = []
  }
  log(...args) {
    this.messages.push(args)
  }
}

/** Log information to the JavaScript console.
*/
class PrefixedLogger extends Logger {
  /** Create a PrefixedLogger.
   *
   * @param {string|true} prefixOrTrue - if true, uses the prefix `"debug"`, otherwise uses the param as the prefix to all
   * messages output.
   */
  constructor(prefixOrTrue) {
    super()
    this.prefix = prefixOrTrue === true ? "debug" : prefixOrTrue
  }

  /** Dumps hte contents of a {@link BufferedLogger} to this logger's output.
   *
   * @param {BufferedLogger} bufferedLogger - a logger with pent-up messages, waiting to be logged.
   */
  dump(bufferedLogger) {
    if (bufferedLogger instanceof BufferedLogger) {
      bufferedLogger.messages.forEach( (args) => {
        this.log(...args)
      })
    }
  }

  log(level,...args) {
    if (typeof(args[0]) === "string") {
      const message = `[prefix:${this.prefix}]:${args[0]}`
      console[level](message,...(args.slice(1)))
    }
    else {
      console[level](this.prefix,...args)
    }
  }
}
export default Logger
