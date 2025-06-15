import { withHTML } from "./SpecHelper.js"

describe("<brut-tabs>", () => {
  withHTML(`
 <brut-tabs tab-selection-pushes-and-restores-state>
   <a role="tab" aria-selected="true"  tabindex="0"  aria-controls="inbox-panel"  id="inbox-tab"
      href="?tab=inbox">Inbox</a>
   <a role="tab" aria-selected="false" tabindex="-1" aria-controls="drafts-panel" id="drafts-tab"
      href="?tab=drafts">Drafts</a>
   <a role="tab" aria-selected="false" tabindex="-1" aria-controls="spam-panel"   id="spam-tab"
      href="?tab=spam">Spam</a>
 </brut-tabs>
 <section role="tabpanel" tabindex="0"  id="inbox-panel">
   <h3>Inbox</h3>
 </section>
 <section role="tabpanel" tabindex="0" id="drafts-panel" hidden>
   <h3>Drafts</h3>
 </section>
 <section role="tabpanel" tabindex="0" id="spam-panel"   hidden>
   <h3>Spam</h3>
 </section>
  `).test("Clicking on a tab sets all attributes properly", ({document,window,assert}) => {

    const selectedTab         = document.querySelector("[role=tab][aria-selected=true]")
    const selectedTabPanel    = document.getElementById(selectedTab.getAttribute("aria-controls"))

    const unselectedTab       = document.querySelector("[role=tab][aria-selected=false]")
    const unselectedTabPanel  = document.getElementById(unselectedTab.getAttribute("aria-controls"))

    unselectedTab.click()

    assert.equal(selectedTab.getAttribute("aria-selected"),"false")
    assert.equal(selectedTab.getAttribute("tabindex"),"-1")
    assert(selectedTabPanel.getAttribute("hidden") != null)

    assert.equal(unselectedTab.getAttribute("aria-selected"),"true")
    assert.equal(unselectedTab.getAttribute("tabindex"),"0")
    assert(unselectedTabPanel.getAttribute("hidden") == null)
    assert.equal(window.history.state["tabId"],unselectedTab.getAttribute("id"))
  })
})
