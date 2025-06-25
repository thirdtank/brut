## Overview

BrutCSS is a simple utility-based CSS library designed to support rapid prototyping and design directly in your HTML.  It is
*not* designed to replace the use of CSS.

BrutCSS has two parts: a design system based on CSS custom properties, and a set of single-purpose CSS classes you can use to
bootstrap the design of your app.

Using BrutCSS is like using any programming language: you use the low-level aspects of it—its classes—to do your work. As you
notice duplication or areas in need of abstraction, you can use any tool at your disposal to do that. You may choose to
create Phlex components to allow the re-use, or you may choose to use CSS classes that you create.

### Example

    <button class="db ph-3 pv-2 bg-white blue-400 b f-3 ba br-2 bc-blue-500">
      Click Me
    </button>

<button class="db ph-3 pv-2 bg-white blue-400 b f-3 ba br-2 bc-blue-500">
  Click Me
</button>

### Using the Design System

    <button class="the-bluest-button">
      Click Me
    </button>

    .the-bluest-button {
      display: block;
      padding-left: var(--sp-3);
      padding-right: var(--sp-3);
      padding-top: var(--sp-2);
      padding-top: var(--sp-2);
      color: var(--blue-400);
      font-weight: bold
      font-size: var(--fs-3);
      border-style: solid
      border-width: 1px;
      border-radius: var(--bw-2)/
      border-color: var(--blue-500);
    }

<button class="db ph-3 pv-2 bg-white blue-400 b f-3 ba br-2 bc-blue-500">
  Click Me
</button>
