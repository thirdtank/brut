import { BrutCustomElements } from "brut-js"

document.addEventListener("DOMContentLoaded", () => {
  BrutCustomElements.define() // Define all of BrutJS's autnomous custom elements
})

// This is duplicated from Brut's LocaleDetection RouteHook and
// must match that value for this to work
const TIMEZONE_COOKIE_NAME = "brut.timezone"

function setTimezoneCookie() {
  if (typeof Intl === "undefined") {
    return
  }
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
  if (!timezone) {
    return
  }
  const secure = location.protocol === "https:" ? "; Secure" : ""
  document.cookie = `${TIMEZONE_COOKIE_NAME}=${timezone}; path=/; max-age=31536000; SameSite=Lax${secure}`
}

setTimezoneCookie()


