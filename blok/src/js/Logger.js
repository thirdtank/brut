class Logger {
  static LEVELS = {
    "debug": 0,
    "info": 1,
    "warn": 2,
    "error": 3,
  }

  static instance = null

  static debug(...args) {
    this.instance.debug(...args)
  }
  static info(...args) {
    this.instance.info(...args)
  }
  static log(...args) {
    this.instance.log(...args)
  }
  static warn(...args) {
    this.instance.warn(...args)
  }
  static error(...args) {
    this.instance.error(...args)
  }

  constructor(argv0) {
    this.prefix = `[ ${argv0} ]`
    this.level = "warn"
  }

  set level(value) {
    this.levelValue = this.constructor.LEVELS[value]
  }

  #addPrefix(args) {
    if (typeof args[0] === "string") {
      args[0] = `${this.prefix} ${args[0]}`
    } else {
      args.unshift(this.prefix)
    }
    return args
  }

  debug(...args) {
    if (this.levelValue <= this.constructor.LEVELS["debug"]) {
      console.debug(...this.#addPrefix(args))
    }
  }
  info(...args) {
    if (this.levelValue <= this.constructor.LEVELS["info"]) {
      console.info(...this.#addPrefix(args))
    }
  }
  log(...args) {
    if (this.levelValue <= this.constructor.LEVELS["info"]) {
      console.log(...this.#addPrefix(args))
    }
  }
  warn(...args) {
    if (this.levelValue <= this.constructor.LEVELS["warn"]) {
      console.warn(...this.#addPrefix(args))
    }
  }
  error(...args) {
    if (this.levelValue <= this.constructor.LEVELS["error"]) {
      console.error(...this.#addPrefix(args))
    }
  }
}
export default Logger
