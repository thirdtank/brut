import BaseCustomElement from "./BaseCustomElement"

/**
 * Send the locale and timezone from the browser to a configured endpoint on the server. This allows
 * the server to have access to a reasonable guess as to the website visitor's locale/timezone.
 *
 * Note that this will not contact the server if both `locale-from-server` and `timezone-from-server` are
 * set.  Further note that this will only contact the server once per page load, unless `url` is changed.
 *
 * @property {String} locale-from-server - omit this if the server doesn't know the visitor's locale. If both this and `timezone-from-server` are set, the server will not be contacted.
 * @property {String} timezone-from-server - omit this if the server doesn't know the visitor's timezone. If both this and `locale-from-server` are set, the server will not be contacted.
 * @property {URL} url - the url to send information to on the server.
 * @property {number} timeout-before-ping-ms - MS to wait until this element contacts the server. A value of 0 will contact the server immediately. The default is 1,000, meaning this element will wait 1 second before contacting the server.
 *
 * @example <caption>When no information about the visitor is known</caption>
 * <brut-locale-detection url="__brut/locale-detection"></brut-locale-detection>
 *
 * @example <caption>When all information about the visitor is known</caption>
 * <brut-locale-detection
 *   url="__brut/locale-detection"
 *   locale-from-server="en-US"
 *   timezone-from-server="America/New_York">
 * </brut-locale-detection>
 *
 * @customElement brut-locale-detection
 */
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
