import BaseCustomElement from "./BaseCustomElement"

class LocaleDetection extends BaseCustomElement {
  static tagName = "brut-locale-detection"

  static observedAttributes = [
    "locale-from-server",
    "timezone-from-server",
    "url",
    "timeout-before-ping-ms",
    "show-warnings",
  ]

  #localeFromServer   = null
  #timezoneFromServer = null
  #reportingURL       = null
  #timeoutBeforePing  = 1000
  #serverContacted    = false

  localeFromServerChangedCallback({newValue}) {
    this.#localeFromServer = newValue
  }

  timezoneFromServerChangedCallback({newValue}) {
    this.#timezoneFromServer = newValue
  }

  urlChangedCallback({newValue}) {
    if (this.#serverContacted) {
      this.#serverContacted = false
    }
    this.#reportingURL = newValue
  }

  timeoutBeforePingMsChangedCallback({newValue}) {
    this.#timeoutBeforePing = newValue
  }

  update() {
    if (this.#timeoutBeforePing == 0) {
      this.#pingServerWithLocaleInfo()
    }
    else {
      setTimeout(this.#pingServerWithLocaleInfo.bind(this), this.#timeoutBeforePing)
    }
  }

  #pingServerWithLocaleInfo() {
    if (!this.#reportingURL) {
      this.logger.info("no url= set, so nowhere to report to")
      return
    }
    if (this.#localeFromServer && this.#timezoneFromServer) {
      this.logger.info("locale and timezone both set, not contacting server")
      return
    }

    if (this.#serverContacted) {
      this.logger.info("server has already been contacted at the given url, not doing it again")
      return
    }
    this.#serverContacted = true

    const formatOptions = Intl.DateTimeFormat().resolvedOptions()
    const request = new Request(
      this.#reportingURL,
      {
        headers: {
          "Content-Type": "application/json",
        },
        method: "POST",
        body: JSON.stringify({
          locale: formatOptions.locale,
          timeZone: formatOptions.timeZone,
        }),
      }
    )

    window.fetch(request).then( (response) => {
      if (response.ok) {
        this.logger.info("Server gave us the OK") 
      }
      else {
        console.warn(response)
      }
    }).catch( (e) => {
      console.warn(e)
    })
  }


}
export default LocaleDetection
