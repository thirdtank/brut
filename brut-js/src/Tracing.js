import { BaseCustomElement } from "brut-js"

/** Sends performance data to an endpoint in a Brut-powered app that is expected to save it as an Open Telemetry span.
 * Uses the W3C-recommended headers "traceparent" and "tracestate" to do this.
 *
 * ### Supported Metrics
 *
 * Currently, this will attempt to send "navigation", "largest-contentful-paint", and "first-contentful-paint" back to the server.
 * Not all browsers support these, so this element will send back as many as it can.  It will wait for all supported metrics to be
 * received before contacting the server. It will attempt to do this exactly once.
 *
 * ### Use
 *
 * To use this element, your page must have a `<meta>` element that contains the value for "traceparent".  It is expected that your
 * server will include this in server-generatd HTML.  The Brut's `Brut::FrontEnd::Components::Traceparent` component will handle this
 * for you. The value for "traceparent" is key to connecting the browser metrics to the back-end request that generated the page.
 *
 * The element also requires a `url` attribute to know where to send the data.  By default, Brut is listening in
 * `/__brut/instrumentation`.  See the example.
 *
 * ### Durations vs Timestamps
 *
 * The performance API produces durations since an origin timestamp.  Open Telemetry wants timestamps.  In theory,
 * `Performance.timeOrigin` is provided by the browser as a reference time when the page started doing anything.
 * In practice, this value is incorrect on Firefox, so the element records a timestamp when it is created.
 *
 * When the data is merged back to the server span, the specific timestamps will not exactly match reality, however the durations will
 * be accurate.  Note that even if `Performance.timeOrigin` was correct, clock drift between client and server would make
 * the timestamps inaccurate anyway.
 *
 * ### Encoding
 *
 * The spec for the "tracestate" header leaves open how the data is to be encoded.  It supports multiple vendors using a key/value
 * pair:
 *
 *     tracestate: honeycomb=«encoded data»,newrelic=«encoded data»
 *
 * This element uses the vendor name "brut". The data is a Base64-encoded JSON blob containing the data. 
 *
 *     tracestate: brut=«Base64 encoded JSON»
 *
 * The values captured and format of the JSON map closely to Open Telemetry's browser instrumentation format.
 * Of course, this element is many magnitudes smaller in size than Open Telemetry's, which is why it exists at all
 *
 * @example
 * <!DOCTYPE html>
 * <html>
 *   <head>
 *     <meta name="traceparent" content="293874293749237439843294">
 *     <brut-tracing url="/__brut/instrumentation"></brut-tracing>
 *     <!-- ... -->
 *   </head>
 *   <body>
 *     <!-- ... -->
 *   </body>
 * </html>
 *
 * @property {string} url - the url where the trace information is to be sent.
 *
 * @see {@link https://www.w3.org/TR/trace-context/}
 * @see external:Performance
 */
class Tracing extends BaseCustomElement {
  static tagName = "brut-tracing"

  static observedAttributes = [
    "url",
    "show-warnings",
  ]


  #url            = null
  #sent           = {}
  #payload        = {}
  #timeOrigin     = null
  #supportedTypes = []

  #performanceObserver = new PerformanceObserver( (entries) => {
    const navigation = entries.getEntriesByType("navigation")[0]
    if (navigation && navigation.loadEventEnd != 0 && !this.#payload.navigation) {
      this.#payload.navigation = this.#parseNavigation(navigation)
    }
    const largestContentfulPaint = entries.getEntriesByType("largest-contentful-paint")
    if (largestContentfulPaint.length > 0 && !this.#payload["largest-contentful-paint"]) {
      this.#payload["largest-contentful-paint"] = this.#parseLargestContentfulPaint(largestContentfulPaint)
    }
    const paint = entries.getEntriesByName("first-contentful-paint", "paint")[0]
    if (paint && !this.#payload.paint) {
      this.#payload.paint = this.#parseFirstContentfulPaint(paint)
    }

    if ( this.#supportedTypes.every( (type) => this.#payload[type] ) ) {
      this.#sendSpans()
      this.#payload = {}
    }
  })

  constructor() {
    super()
    this.#timeOrigin = Date.now()
    this.#supportedTypes = [
      "navigation",
      "largest-contentful-paint",
      "paint",
    ].filter( (type) => {
      return PerformanceObserver.supportedEntryTypes.includes(type)
    })
  }

  urlChangedCallback({newValue}) {
    this.#url = newValue
  }

  update() {
    this.#supportedTypes.forEach( (type) => {
      this.#performanceObserver.observe({type: type, buffered: true})
    })
  }

  #sendSpans() {
    const headers = this.#initializerHeadersIfCanContinue()
    if (!headers) {
      return
    }
    const span = this.#payload.navigation

    if (this.#payload.paint) {
      span.events.push({
        name: this.#payload.paint.name,
        timestamp: this.#timeOrigin + this.#payload.paint.startTime
      })
    }
    if (this.#payload["largest-contentful-paint"]) {
      this.#payload["largest-contentful-paint"].forEach( (event) => {
        span.events.push({
          name: event.name,
          timestamp: this.#timeOrigin + event.startTime,
          attributes: {
            "element.tag": event.element?.tagName,
            "element.class": event.element?.className,
          }
        })
      })
    }

    this.#sent[this.#url] = true
    headers.append("tracestate",`brut=${window.btoa(JSON.stringify(span))}`)
    const request = new Request(
      this.#url,
      {
        headers: headers,
        method: "GET",
      }
    )
    fetch(request).then( (response) => {
      if (!response.ok) {
        console.warn("Problem sending instrumentation: %s/%s", response.status,response.statusText)
      }
    }).catch( (error) => {
      console.warn("Problem sending instrumentation: %o", error)
    })
  }

  #parseNavigation(navigation) {
    const documentFetch = {
      name: "browser.documentFetch",
      start_timestamp: navigation.fetchStart + this.#timeOrigin,
      end_timestamp: navigation.responseEnd + this.#timeOrigin,
      attributes: {
        "http.url": navigation.name,
      },
    }
    const events = [
      "fetchStart",
      "unloadEventStart",
      "unloadEventEnd",
      "domInteractive",
      "domInteractive",
      "domContentLoadedEventStart",
      "domContentLoadedEventEnd",
      "domComplete",
      "loadEventStart",
      "loadEventEnd",
    ]

    return {
      name: "browser.documentLoad",
      start_timestamp: navigation.fetchStart + this.#timeOrigin,
      end_timestamp: navigation.loadEventEnd + this.#timeOrigin,
      attributes: {
        "http.url": navigation.name,
        "http.user_agent": window.navigator.userAgent,
      },
      events: events.map( (eventName) => {
        return {
          name: eventName,
          timestamp: this.#timeOrigin + navigation[eventName],
        }
      }),
      spans: [
        documentFetch
      ]
    }
  }

  #parseFirstContentfulPaint(paint) {
    return {
      name: "browser.first-contentful-paint",
      startTime: paint.startTime,
    }
  }

  #parseLargestContentfulPaint(largestContentfulPaint) {
    return largestContentfulPaint.map( (entry) => {
      return {
        name: "browser.largest-contentful-paint",
        startTime: entry.startTime,
        element: entry.element,
      }
    })
  }

  #initializerHeadersIfCanContinue() {
    if (!this.#url) {
      this.logger.info("No url set, no traces will be reported")
      return
    }
    const $traceparent = document.querySelector("meta[name='traceparent']")
    if (!$traceparent) {
      this.logger.info("No <meta name='traceparent' ...> in the document, no traces can be reported")
      return
    }
    if (this.#sent[this.#url]) {
      this.logger.info("Already sent to %s", this.#url)
      return
    }
    const traceparent = $traceparent.getAttribute("content")
    if (!traceparent) {
      this.logger.info("%o had no value for the content attribute, no traces can be reported",$traceparent)
      return
    }
    return new Headers({ traceparent })
  }
}
export default Tracing
