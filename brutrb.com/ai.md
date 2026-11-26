# AI Declaration and Notes

LLMs and AI tools are a current fact of life.  We feel it's important to be realistic and up front about
how they affect this project.

## Levels of AI Use

I created [declare-ai.org](https://declare-ai.org/) to allow precise documentation of how AI is used in a
project. It defines four levels of AI use:

1. No involvement at all.
2. Non-create assistance, such as the completions GitHub Copilot may make while you are typing.
3. Creative assistance, where an AI generated a large amount of code that you then modified. An example would be using a tool like Cursor to write code for your review.
4. Completely Produced by an AI, for example if you used Stable Diffusion to create your icon.

## Code

The entirety of Brut's codebase could be grouped into three parts:

* The library code developers use. This is, roughly, the code in `lib`, `brut-js/src`, and `brut-css/src`.
* Tests of the library code.
* Tools used to manage the library code, such as what's in `bin/`, `brut-js/bin`, `brut-css/bin`, etc.

### Library Code Should Be Written By a Person

We want the library code written by a person, i.e. it should have level 1 AI assistance: none.  As of this writing—Nov 26, 2026—all library code was written by a person.

If some code is level 2—non-creative assistance—that is probably fine.

### Tests Should Not Be Totally Written by AI

As of this writing—Nov 26, 2026—the library has some automated tests with the `adrs.cloud` app serves as a more complete test suite.

The tests that are here are a mixture of tests written by a person and tests written by an AI but
*reviewed* by a person.  To be specific, AI-written tests were at my request and then reviewed by me, often edited after the fact.  My goal is to have tests that I could understand and change, using the AI to essentially backfill tests that didn't exist at all.

This is fine - tests must never be written entirely by an AI without human review (level 4).

In any case, the author of a test should understand it and the maintainers must be able to understand and modify all tests without the use of AI tools.

### Management Tools Should Not Be Totally Written by AI

Like tests, management tools must be comprehensible by a person and the creator of the code must understand it.  That said, some of the tools were created with level 3 AI assistance, and we expect these
tools may continue to be created this way.

Nevertheless, this code must be reviewed and understood by a person.

## Documentation

We strive to have all documentation written by a real person.  None of this documentation, or the API
documentation, is produced by a machine, although spelling and grammar corrections will certainly have been suggested by automated tools.

We expect an LLM to be able to digest this documentation and source code and provide alternate analysis of how Brut works and how to use it.  We hope such analysis is correct and useful, however that cannot be guaranteed, so this documentation is the second best source of truth, the source code being the best.

## Logos

While the various logos look like someone typed "make me a logo in the style of the Washington, DC Metro", if you look closely, you will see the telltale sings that they were made by a person…a person who is not a professional designer.

As such, these are all Level 1.

## AI Information about Brut Should Be Viewed with Skepticism

* **LLMs with access to Brut's source code tend to give reasonable answers**.  You should treat these
answers with some skepticism as they will be based only on Brut's code.
* **Answers from an LLM about Brut without source access are likely incorrect.** LLMs will certainly not
have been trained on information about Brut, since it is new.
