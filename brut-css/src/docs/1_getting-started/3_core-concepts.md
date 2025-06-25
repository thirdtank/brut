## Core Concepts

BrutCSS is heavily inspried by [Tachyons](https://tachyons.io), which is similar to TailwindCSS at a very high level, but
conceptually different.  Brut's goal is not to eliminate CSS from your project. Instead, it's to allow you to iterate quickly
on design in the browser.

BrutCSS achieves based on two values:

* **You don't need 200 font sizes.**  Brut provides you with 10, which is probably enough for most design problems.
* **You (should) already know CSS.** In BrutCSS, to get a `font-weight` of 300, you'd use the class `fw-300`, which you can
quickly learn stands for **f**ont-**w**eight **300**. In Tailwind, you have to look up what class to use (it's `font-light`).

With these values at the front of the design, this leads to two mindsets:

* **Designing in the Browser is fast.** Being able to edit *only* your HTML template while doing design is extremely fast and
low friction. Especially when you consider that you don't have infinite classes/decisions, and your classes are easily
guessable from the CSS you already know.
* **CSS is Powerful.** Single-function classes are great, but they become unweildy when trying to use more modern features of
CSS, especially in the context of web components. What is trivial in CSS becomes a very long list of esoteric classes and a
lengthy build step.

Thus, a BrutCSS-powered app is going to have a mix of single- and special-purpose classes.  This is fine.  Just as we rely on
multiple techniques for managing re-use in our JavaScript or Ruby code, so it is with CSS.

### Design System

Brut's *design system* is a set of *custom properties*.  They work together to define a basic grid, a modular scale, and a
color palette. You can change this easily by changing the value of the custom properties.

### Single Purpose Classes

Brut includes *single-purpose classes* that apply common values for common CSS attributes.  Brut does not aim to provide
access to *all* of CSS with single-purpose classes.  You can add your own if you need to.

Brut's classes follow a strict naming convention that is either a mnemonic for a CSS attribute, or the attribute spelled out, coupled with either a numeric step in some scale, or the value to use.

* `fw-3` is `font-weight: 300`
* `pa-3` sets `padding` to size 3 of the scale
* `justify-between` sets `justify-content` to `between`
* etc.

The goal is to capitalize on the knowledge you have of CSS, and allow you to reasonably guess the other values once you learn
a few of them.  There is a minimum of abstractions in the names of the classes.  For example, Tailwind's third step of its
`border-radius` scale is called `rounded-ms`. In BrutCSS, this is `br-3`.

### Width-Based/Breakpoint Classes

Brut provides breakpoint-specific versions of each class to allow you apply the class' attribute's value only at certain
widths.  The following code will use the third font size by default, which are small screens, the fourth size on screens
between 30 and 60em and the fifth size on screens larger than 60em:

    <div class="f-3 f-4-m f-5-l">
      Responsive Design!
    </div>

### Pseudo Classes

Brut also provides a limited number of classes available for pseudo-states, namely `:hover`.  This link will show an
underline via `text-decoration: underline` (tdu) only when the user agent is capable of hovering and actually *is* hovering.
Otherwise, there is no text decoration:

    <a href="#" class="tdn hover-tdu">
      Click Me, or Just Hang Around
    </a>

It's the equivalent of this:

    a {
      text-decoration: none;
    }
    @media(hover: hover) {
      a:hover {
        text-decoration: underline;
      }
    }
