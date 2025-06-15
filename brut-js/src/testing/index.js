/**
 * Enables and implements a basic testing system for custom elements. This uses JSDOM and some hacks to allow
 * you to test your custom elements using a DOM-like experience, but without having to run a real browser.
 * It is designed to have very few dependencies to ensure the least amount of configuration and tool
 * debt.
 *
 * It assumes you are using Mocha.  To create a test, create a file named `Whatever.spec.js` in the folder where you are running
 * Mocha.  Convention is that `Whatever` is the name of your custom element's class.
 *
 * @example
 * import { withHTML } from "../src/testing/index.js"
 *
 * describe("<some-element>", () => {
 *   withHTML(`
 *   <some-element>OK</some-element>
 *   `).test("lower-cases its contents", ({document,assert}) => {
 *     const element = document.querySelector("some-element")
 *     assert.equal(element.textContent,"ok")
 *   })
 * })
 *
 * @module testing
 */
import AssetMetadata from "./AssetMetadata.js"
import CustomElementTest from "./CustomElementTest.js"

/**
 * Bootstraps a test based on some HTML and configuration about where the bundled custom elements are. It's recommended that you
 * create the method `withHTML` in your `SpecHelper.js` file to set up the asset metadata stuff.
 *
 * This returns a {@link module:testing~CustomElementTest}, on which you can call additional setup methods, or start defining tests with the 
 * {@link module:testing~CustomElementTest#test} method.
 *
 * @param {String} html - HTML that should be in the document for the test
 * @param {Object} assetMetadata - a JSON object describing where the bundles are.  This is needed to allow JSDOM to load the custom
 * elements as if it were served up by a webserver
 * @param {String} publicRoot - The root to where JS files.  When using this in a BrutRB web app, this would be where your bundled
 * files are placed for serving.
 *
 * @see module:testing~CustomElementTest
 */
const createTestBasedOnHTML = ({html,assetMetadata,publicRoot}) => {
  return new CustomElementTest(html,null,new AssetMetadata(assetMetadata,publicRoot))
}

export {
  createTestBasedOnHTML
}
