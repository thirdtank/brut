# AGENT.md

Guidance for coding agents working in this repo.

## What this is

Brut is an opinionated, standards-based Ruby web framework. The repo currently contains:

- `lib/` — **BrutRB**, the Ruby framework/gem (main code)
- `brutrb.com/` — documentation website (VitePress), the source of user-facing docs

**Ignore `brut-js/` (BrutJS) and `brut-css/` (BrutCSS).** They will be removed/replaced. Ignore references to them in docs, scripts, and tests unless doing so would cause confusion; do not modify them.

Other notable dirs: `specs/` (Ruby tests, mirroring `lib/`), `templates/` (new-app template), `exe/brut` (CLI), `bin/` (workspace scripts), `dx/` (Docker dev environment).

## Environment

Development is Docker-based. Normally:

```
dx/build          # build image
dx/start          # start containers
dx/exec <cmd>     # run a command inside the container
dx/stop           # stop containers
```

If you are already running inside the dev container (e.g. under the `pi` agent), run commands **directly** — `dx/exec` requires Docker and will not work from inside. One-time setup: `bin/setup --no-credentials`.

Ruby is 4.0; Node is also available.

## Common commands

- **Ruby tests** — `bin/test` (all) or `bin/test path/to/file.spec.rb`
- **Single test directly** — `bin/rspec -I specs --require spec_helper specs/path/to/file.spec.rb`
- **Lint** — `bin/generate-and-run-rubocop`
- **Full CI** — `bin/ci` (Ruby tests + lint; also runs BrutJS/BrutCSS — ignore those)
- **Build docs** — `bin/docs` (YARD API + VitePress site into `docs/`)
- **Docs site dev server** — `bin/dev` (serves `brutrb.com` at :8086)

Test files are `*.spec.rb` (not `*_spec.rb`) and live under `specs/`.

## Generated files — do not hand-edit

- `.rubocop.yml` is generated from `lib/brut/rubocop_config.rb`. Edit the Ruby source, then run `bin/generate-and-run-rubocop`.
- `docs/` is build output from `bin/docs`. Edit `brutrb.com/*.md` or YARD comments in `lib/`, not `docs/`.
- `brutrb.com/public/api/` is generated YARD output.

## Conventions

Rubocop is the authority; a few notable rules:

- `unless`, `until`, and `and`/`or`/`not` are **disallowed**; use `if`, `while`, `&&`/`||`/`!`.
- Method definitions: `def self.foo` (not `class << self`), parentheses on defs.
- Leading dots on multiline chains (`Layout/DotPosition: trailing`).
- Prefer `detect`/`select`/`map`/`include?`; use `each`, never `for`.
- Trailing commas in multiline arrays/hashes.

Terminology (see `brutrb.com/doc-conventions.md`): the files in `specs/` are **tests**, not "specs"; apps have **visitors**, not users; HTML is **generated**, not rendered; forms have **constraints**; Ruby classes have **initializers**. Write **Brut**/**BrutRB**.

## AI contribution policy

Unless specifically asked, do not write code in `lib/`.  You can modify it while working to test
theories or validate tests, but restore it to how it was at each break in the conversation.  `lib/` is
to be edited be people always.

## When Writing Code

* Do not comment things unless necessary to explain why weird code was written.
