import BaseCustomElement from "./BaseCustomElement"

/** Implements an in-page tab selector.  It's intended to wrap a set of `<a>` or `<button>` elements
 * that represent the tabs of a tabbed UI, as defined by ARIA roles.  
 *
 * Each direct child must be an `<a>` or a `<button>`, though `<a>` is recommended.
 * Any other elements are ignored.  Each `<a>` or `<button>`
 * (herafter referred to as "tab") must have the correct ARIA attributes:
 *
 * * `role="tab"`
 * * `aria-selected` as true or false, depending on what tab is selected when the page is first rendered.  This
 *   custom element will ensure this value is updated as different tabs are selected.
 * * `tabindex` should be 0 if selected, -1 otherwise. This custom element will ensure this value is updated as
 *   different tabs are selected.
 * * `aria-controls` to the ID or list of IDs of panels that should be shown when this tab is selected.
 * * `id` to allow the `tab-panel` to refer back to this tab.
 *
 * This custom element will set click listeners on all tabs and, when clicked, hide all panels referred to by
 * every tab (by setting the `hidden` attribute), then show only those panels referred to by the clicked
 * tab.  You can use CSS to style everything the way you like it.
 *
 * @property {boolean} tab-selection-pushes-and-restores-state if set, this custom element will use the 
 *                                                             history API to manage state. When a tab
 *                                                             implemented by an `<a>` with an `href` is
 *                                                             clicked, that `href` will be pushed into 
 *                                                             the state.  When the back button is hit,
 *                                                             this will select the previous tab as selected.
 *                                                             Note that this will conflict with anything else
 *                                                             on the page that manipulates state, so only
 *                                                             set this if your UI is a "full page tab"
 *                                                             style UI.
 *
 * @fires Tabs#brut:tabselected whenever the tab selection has changed
 * @example
 * <brut-tabs>
 *   <a role="tab" aria-selected="true"  tabindex="0"  aria-controls="inbox-panel"  id="inbox-tab"
 *      href="?tab=inbox">Inbox</a>
 *   <a role="tab" aria-selected="false" tabindex="-1" aria-controls="drafts-panel" id="drafts-tab"
 *      href="?tab=drafts">Drafts</a>
 *   <a role="tab" aria-selected="false" tabindex="-1" aria-controls="spam-panel"   id="spam-tab"
 *      href="?tab=spam">Spam</a>
 * </brut-tabs>
 * <section role="tabpanel" tabindex="0"  id="inbox-panel">
 *   <h3>Inbox</h3>
 * </section>
 * <section role="tabpanel" tabindex="0" id="drafts-panel" hidden>
 *   <h3>Drafts</h3>
 * </section>
 * <section role="tabpanel" tabindex="0" id="spam-panel"   hidden>
 *   <h3>Spam</h3>
 * </section>
 * <!-- if a user clicks on 'Drafts', the DOM will be updated to look
 *      effectively like so: -->
 * <brut-tabs>
 *   <a role="tab" aria-selected="false" tabindex="-1" aria-controls="inbox-panel"  id="inbox-tab"
 *      href="?tab=inbox">Inbox</a>
 *   <a role="tab" aria-selected="true"  tabindex="0"  aria-controls="drafts-panel" id="drafts-tab"
 *      href="?tab=drafts">Drafts</a>
 *   <a role="tab" aria-selected="false" tabindex="-1" aria-controls="spam-panel"   id="spam-tab"
 *      href="?tab=spam">Spam</a>
 * </brut-tabs>
 * <section role="tabpanel" tabindex="0"  id="inbox-panel"  hidden>
 *   <h3>Inbox</h3>
 * </section>
 * <section role="tabpanel" tabindex="-1" id="drafts-panel">
 *   <h3>Drafts</h3>
 * </section>
 * <section role="tabpanel" tabindex="-1" id="spam-panel"   hidden>
 *   <h3>Spam</h3>
 * </section>
 *
 */
class Tabs extends BaseCustomElement {
  static tagName = "brut-tabs"
  static observedAttributes = [
    "tab-selection-pushes-and-restores-state",
    "show-warnings",
  ]

  tabSelectionPushesAndRestoresStateChangedCallback({newValue,oldValue}) {
    this.#pushAndRestoreTabState = newValue != null
  }

  update() {
    this.#tabs().forEach( (tab) => {
      tab.addEventListener("click", this.#tabClicked)
    })
  }

  #pushAndRestoreTabState = false

  #tabClicked = (event) => {
    event.preventDefault()
    this.#setTabAsSelected(event.target)
    event.preventDefault()
  }

  #reloadTab = (event) => {
    const tab = document.getElementById(event.state.tabId)
    if (tab) {
      this.#setTabAsSelected(tab, { skipPushState: true })
    }
  }

  #setTabAsSelected(selectedTab, { skipPushState = false } = {}) {
    this.#tabs().forEach( (tab) => {
      const tabPanels = []
      const ariaControls = tab.getAttribute("aria-controls")
      if (ariaControls) {
        ariaControls.split(/\s+/).forEach( (id) => {
          const panel = document.getElementById(id)
          if (panel) {
            tabPanels.push(panel)
          }
          else {
            this.logger.warn("Tab %o references panel with id %s, but no such element exists with that id",tab,id)
          }
        })
      }
      if (tab == selectedTab) {
        tab.setAttribute("aria-selected",true)
        tab.setAttribute("tabindex","0")
        tabPanels.forEach( (panel) => panel.removeAttribute("hidden") )
        if (this.#pushAndRestoreTabState && !skipPushState)  {
          let href = tab.getAttribute("href") || ""
          if (href.startsWith("?")) {
            let hrefQueryString = href.slice(1)
            const anchorIndex = hrefQueryString.indexOf("#")
            if (anchorIndex != -1) {
              hrefQueryString = hrefQueryString.slice(-1 * (hrefQueryString.length - anchorIndex - 1))
            }
            const currentQuery = new URLSearchParams(window.location.search)
            const hrefQuery    = new URLSearchParams(hrefQueryString)
            hrefQuery.forEach( (value,key) => {
              currentQuery.set(key,value)
            })
            href = "?" + currentQuery.toString() + (anchorIndex == -1 ? "" : hrefQueryString.slice(anchorIndex))
          }
          window.history.pushState({ tabId: tab.id },"",href)
          window.addEventListener("popstate", this.#reloadTab)
        }
        this.dispatchEvent(new CustomEvent("brut:tabselected", { tabId: tab.id }))
      }
      else {
        tab.setAttribute("aria-selected",false)
        tab.setAttribute("tabindex","-1")
        tabPanels.forEach( (panel) => panel.setAttribute("hidden", true) )
      }
    })
  }


  #tabs() {
    const tabs = []
    this.querySelectorAll("[role=tab]").forEach( (tab) => {
      if ( (tab.tagName.toLowerCase() == "a") || (tab.tagName.toLowerCase() == "button") ) {
        tabs.push(tab)
      }
      else {
        this.logger.warn("An element with tag %s was assigned role=tab, and %s doesn't work that way. Use an <a> or a <button>",tab.tagName,this.constructor.name)
      }
    })
    return tabs
  }

}
export default Tabs
