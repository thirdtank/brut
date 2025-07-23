# Brut - The Raw, Simple, Powerful, Standards-Based Web Framework

Brut is a way to make web apps with Ruby, captializing on the knowledge you have—HTTP, HTML, CSS, JavaScript, SQL—without requiring
*too* much extra stuff to learn.

![Brut Logo in the style of the Washington DC Metro.  It has the metro brown background with all text in white Helvetica.  Centered at the top is "BrutRB". Below that, in the style of metro stops is "Ruby", next to a red dot with "RB" in it, "HTML/CSS/JS" next to an orange dot with "WP" in it, "Phlex" next to a blue dot with "PL" in it, and "RSpec" next to a green dot with "RS" in it.](brutrb.com/images/LogoStop.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "brut"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install brut

## Getting Started

[Please note there is extensive documentation](https://brutrb.com), however to get started, you can use [mkbrut](https://github.com/thirdtank/mkrbut):

```
docker run --pull always \
           -v "$PWD":"$PWD" \
           -w "$PWD" 
           -it \
           thirdtank/mkbrut \
           mkbrut your-new-app
```

If you have Ruby 3.4 installed somewhere, you can use this via RubyGems as well:

```
> gem install mkbrut
> mkbrut your-new-app
```

## Developing

The dev environment is managed by Docker and you are encouraged to use this. It's set up so you can edit your code on your computer
with your editor, but all commands are run inside Docker, which should be more consistent across developer workstations.

1. On Windows, setup WSL2
2. Install Docker
3. Build the image(s) you will use to start containers where development happens:

        dx/build
4. Start up the dev environment

        dx/start
5. At this point, you can "log in" to the virtual machine/docker container via:

        dx/exec bash
6. From there, you have a UNIX prompt where you can run all commands.  You can also run any command via:

        dx/exec ls -l # or whatever

   This is how you can configure your editor to issue commands and access their output.

7. To set everything up:

        dx/exec bin/setup --no-credentials

   The `--no-credentials` means that you will not be able to push to GitHub or RubyGems from within the Docker container. This ability is only needed by maintainers to push new versions of the gem. You can push to GitHub from your computer.

### Conventions in MonoRepo

This repo contains all five main parts of Brut:

* BrutRB, the Ruby web framework (in this directory, code in `lib`)
* BrutJS, the JS library with custom elements (in `brut-js/`)
* BrutCSS, the CSS library (in `brut-css/`)
* `mkbrut`, the CLI to create new Brut apps (in `mkbrut/`)
* `brutrb.com`, the website, powered by VitePress (in `brutrb.com`)

Each repo must conform to the *Workspace Protocol*, which are scripts in `bin/` that perform certain tasks:

* `bin/setup` - performs any setup
* `bin/docs` - builds all documentation, placing it where `brutrb.com` can find it.
* `bin/build` - builds deployable artifacts, if needed
* `bin/ci` - runs all tests, if applicable

The primary `bin` scripts at the root work for both BrutRB, the web framework, and recurse into the other directories to perform their
actions as well.
