import BaseCustomElement           from "./BaseCustomElement"
import AjaxSubmit                  from "./AjaxSubmit"
import Autosubmit                  from "./Autosubmit"
import ConfirmSubmit               from "./ConfirmSubmit"
import ConfirmationDialog          from "./ConfirmationDialog"
import ConstraintViolationMessage  from "./ConstraintViolationMessage"
import ConstraintViolationMessages from "./ConstraintViolationMessages"
import CopyToClipboard             from "./CopyToClipboard"
import Form                        from "./Form"
import I18nTranslation             from "./I18nTranslation"
import LocaleDetection             from "./LocaleDetection"
import Message                     from "./Message"
import RichString                  from "./RichString"
import Tabs                        from "./Tabs"
import Tracing                     from "./Tracing"

/**
 * This is the code for a test case. It may return a {@link external:Promise} if there is async behavior that must
 * be waited-on to properly assert behavior.
 *
 * @callback testCodeCallback
 *
 * @param {Object} objects - objects passed into your test that you may need.
 * @param {Window} objects.window - Access to the top-level window object. Note that this provided by JSDOM and is not exactly like the `Window` you'd get in your browser.
 * @param {Document} objects.document - Access to the top-level document object. Note that this provided by JSDOM and is not exactly like the `Document` you'd get in your browser.
 * @param {Object} objects.assert - The NodeJS assert object that you should use to assert behavior.
 * @param {Object} objects.fetchRequests - An array of `Request` instances given to `fetch`.  This will be updated as `fetch` is
 * called and can be useful to assert the contents of what was requested via `fetch`.
 *
 * @example
 * test("some test", ({document,assert}) => {
 *   const element = document.querySelector("div")
 *   assert(div.getAttribute("data-foo") != null)
 * })
 *
 * @example
 * test("some other test", ({document,window,assert}) => {
 *   const element = document.querySelector("div")
 *   assert.equal(window.history.state["foo"], "bar")
 * })
 */

/**
 * @external Performance
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/Performance|Performance API}
 */

/**
 * @external Promise
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise|Promise}
 */
/**
 * @external fetch
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch|fetch}
 */

/**
 * @external ValidityState
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/ValidityState|ValidityState}
 */

/**
 * The standard `CustomElementRegistry`
 *
 * @external CustomElementRegistry
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/CustomElementRegistry|CustomElementRegistry}
 */

/**
 * @external Window
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/Window/|Window}
 */

/** 
 * @method confirm
 * @memberof external:Window#
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/Window/confirm|confirm}
 */

/**
 * Class that can be used to automatically define all of brut's custom
 * elements.
 */
class BrutCustomElements {
  static elementClasses = []
  static define() {
    this.elementClasses.forEach( (e) => {
      e.define() 
    })
  }
  static addElementClasses(...classes) {
    this.elementClasses.push(...classes)
  }
}

BrutCustomElements.addElementClasses(
  // Ordering is important here - TBD how to make sure these are created in order
  I18nTranslation,
  CopyToClipboard,
  Message,
  ConfirmSubmit,
  ConfirmationDialog,
  ConstraintViolationMessages,
  Form,
  AjaxSubmit,
  ConstraintViolationMessage,
  Tabs,
  LocaleDetection,
  Autosubmit,
  Tracing,
)

export {
  AjaxSubmit,
  Autosubmit,
  BaseCustomElement,
  BrutCustomElements,
  ConfirmSubmit,
  ConfirmationDialog,
  ConstraintViolationMessage,
  ConstraintViolationMessages,
  Form,
  I18nTranslation,
  LocaleDetection,
  Message,
  RichString,
  Tabs,
  Tracing
}

