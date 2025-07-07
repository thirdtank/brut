# Language Server Protocol (LSP) Support

Because Brut development happens inside Docker, but your editor likely runs on your
computer, getting LSP servers running takes a few more steps.

## Overview

When you created your app with `mkbrut`, the following LSP-related modules are set
up and/or installed:

* Shopify's Ruby LSP server (installed from `bin/setup`)
* Microsoft's TypeScript/JavaScript and CSS LSP serfvers (specified in `package.json`, installed when `npm install` runs from `bin/setup`)

In order to use them from your computer a few configurations are needed, some of
which Brut has done, and some you will need to do.

| Configuration | Description | Brut Handled? |
|---|---|---|
| Paths inside Docker Must Match Your Computer | When an LSP server communicates about a file, it does so with a path. That means that paths inside the Docker container must be the same as those on your computer.  Brut achievecs this by using `${CWD}` inside `docker-compose.dx.yml` | ✅ |
| Third party libraries must *also* be installed in a path that is the same in both places | When jumping to a definition, the LSP server will again use paths, which must match.  Because Node modules are installed local to your app, they already work.  Ruby Gems, however, are configured to be installed in `local-gems` in your app.  Brut should've added this to `.gitignore` and setup everything inside Docker to use it. | ✅ |
| Your editor must use `dx/exec` to execute LSP commands | Your editor will need to know that the LSP servers are running inside Docker.  If your editor allows configuring the commands used to do this, you must prefix them with `dx/exec`. See [my blog post](https://naildrivin5.com/blog/2025/06/12/neovim-and-lsp-servers-working-with-docker-based-development.html) for details. | ❌ |
| Other languages or plugins to existing LSP servers | I haven't used these, so no idea how well they work. | ❌ |

