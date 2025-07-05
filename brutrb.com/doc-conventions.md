# Documentation Conventions

## Terminology

Brut attempts to use existing terminology where possible, particularly where that technology applies to the web platform.  For example, there is not a thing called "CSS variables", rather the term is "custom properties".

Here are some common exampels:


- HTML entities are **elements** or **tags**
- HTML elements have **attributes**.
- Forms don't have validations, they have **constraints** which are **violated** by invalid data.
- Ruby classes don't have constructors, they have **initializers**.
- Invoking behavior on a Ruby object is **calling a method**, not sending a message.
- Despite being in `specs/`, the files in there are **tests**, not specifications or
-specs".
- Tests that use a browser are **end to end** or **e2e** tests.
- HTML is not rendered, but **generated**. The browser renders the HTML sent to it by the server, along with the CSS.
- Your app or site doesn't have users, it has **visitors**.

## Structure of These Documents

Each page here documents on aspect of Brut, called a *module*, and these pages are organized along four sections:

* **Overview** - What the module does, how it works, and a brief example.
* **Testing** - How to test the code you write in this module.
* **Recommended Practices** - Opinions from the creators about how best to think about the code in this module.
* **Technical Notes** - details about the technical implementations that may be
useful as context.

## Names of the Library and Associated Modules

This framework is called "Brut" though may be called "BrutRB" or "brut-rp".  It lives at `brutrb.com`.  Never use "brutRB", "brut_rb", etc.

The JavaScript library is called "BrutJS", but is `brut-js` in code or the filesystem. "Brut-JS" is wrong, as is `brut_js`.

The CSS library is called "BrutCSS", but is `brut-css` in code or the filesystem. "Brut-CSS" is wrong, as is "brut-css".


## On Using VitePress

This site is built using [VitePress](https://vitepress.dev), which is a client-side heavy framework.  It kinda goes against the ethos of Brut, but it is allowing me to write documentation that looks decent and is mostly navigable.  I would like to use a more accessible, customized system for documenting Brut, but for now, it's more important to get the documentation out.  A better documentation experience is planned.
