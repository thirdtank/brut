# Documentation Conventions

## Terminology

Brut attempts to use existing terminology where possible, particularly where that technology applies to the web
platform.  For example, there is not a thing called "CSS variables", rather the term is "custom properties". HTML entities are *elements* or *tags* that have *attributes*. As another example, HTML doesn't have *validations*, rather it as *constraints*, which can be *violated*.

When speaking about Ruby, we prefer the term *initializer* over constructor, *parameters* over arguments, and
*methods* over messages.  We also prefer *tests* over specs, however test files *are* located in `specs/` and
named `*.spec.rb` to be consistent with RSpec's nomenclature.  We prefer *end-to-end* or *e2e* tests instead of
browser tests or request specs. 

Lastly, Brut doesn't render HTML, it *generates* it.  The browser renders the HTML for the website's visitor.

## Structure of These Documents

Each page here documents on aspect of Brut, called a *module*, and these pages are organized along four sections:

* **Overview** - provides detailed information on how this part of Brut works, with minimal examples to orient you to
the terms and design of that module.  Links to reference documentation are provided inline as needed.
* **Testing** - information about how to write tests for the code in this module.  For example, in [Pages](/pages), we detail how you are intended to test page classes.
* **Recommended Practices** - this section outlines what we believe is the best way to use the module, along with
justifications for the recommended approach.  While you are free to ignore this advice, it's often useful to
understand the intention of the authors.
* **Technical Notes** - where appropriate, technical details about how or why the module works the way it does
are provided.  This section should be marked with a date to allow you to understand the recency of the
information. It may not always be up to date, but this can help further clarify what is happening under the
covers and why.

## LLMs and Other Artificially-Intellgient Support

We strive to have all documentation written by a real person.  None of this documentation is produced by a
machine, although spelling and grammar corrections will certainly have been suggested by automated tools.

We expect an LLM to be able to digest this documentation and source code and provide alternate analysis of how
Brut works and how to use it.  We hope such analysis is correct and useful, however that cannot be guaranteed, so
this documentation is the second best source of truth, the source code being the best.

## On Using VitePress

This site is built using [VitePress](https://vitepress.dev), which is a client-side heavy framework.  It kinda goes against the ethos of Brut, but it is allowing me to write documentation that looks decent and is mostly navigable.  I would like to use a more accessible, customized system for documenting Brut, but for now, it's more important to get the documentation out.  A better documentation experience is planned.
