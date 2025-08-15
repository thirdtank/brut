# Tutorials

Below are several tutorials, along with screencasts showing the tutorial steps as a video.  The first one is to [build a blog in 15 minutes](https://video.hardlimit.com/w/ae7EMhwjDq9kSH5dqQ9swV). The remainder of the tutorials assumey you are going in order, however code for each starting point is available, so you can skip around.

If you'd just like to read source code, there are two apps you can check out:

* [The blog we'll build here](https://github.com/thirdtank/blog-demo)
* [ADRs.cloud](https://github.com/thirdtank/adrs.cloud), which is a more realistic app that has
  mulitple database tables, progressively-enhanced UI, and background jobs.

You can be running either of these locally in minutes as long as you have Docker installed.

## Understanding These Tutorials

These tutorials will show you command line invocations and code.  You should be able to follow along and just type what we say and it should work.

That said, it's not always clear what we are talking about.

### Understanding Command Line Invocations

If you aren't comfortable on the command line, it can be hard to understand what parts of this tutorial represent stuff you should type/paste and what is output from those commands.  Here is how that works.

When we want you to run a command, the preceding text will tell you something like "run this command", and then you'll see a codeblock that has the label "bash" in the upper right corner, like so:

```bash
ls -l
```

If you hover over it, an icon with the tooltip "Copy Code" will appear on the right, and you can click that to copy the command-line invocation. Or, you can select it and copy it, or you can type it in manually.

In any case, you are expected to type/paste/execute the entire thing.  Other parts of this documentation site may precede command lines with `>` to indicate it's a shell command. For this tutorial, we aren't doing that.

Sometimes, commands are long. They can be split up by entering a backslash (`\`) as the last character of a line, hitting return, and continuing the command.  For example this command:

```bash
git push origin main
```

Could be executed like so:

```bash
git push \
    origin \
    main
```

In both cases, you can copy/type these as written and they will work.

To show output of a command, a separate code block will be used, and the first line of the output will be the string `# OUTPUT:`, and there should **not** be a "bash" label in the upper right corner:

```
# OUTPUT
app                    dx                   puma.config.rb
bin                    Gemfile              README.md
config.ru              package.json         specs
docker-compose.dx.yml  Procfile.development
Dockerfile.dx          Procfile.test
```

Sometimes, output is very long and very irrelevant. In that case, the string `«LOTS OF OUTPUT»` will be used as a placeholder:

```
# OUTPUT
app
dx
puma.config.rb
«LOTS OF OUTPUTS»
```

### Understanding Code Changes

In most cases, we'll show you the entire code for a file/class, and you should make your copy look like it.  Suppose you have this:

```ruby
class SomeComponent < AppComponent
end
```

We might say "add the `view_template` to your component so it looks like this:"

```ruby
class SomeComponent < AppComponent
  def view_template
    h3 { "My component" }
    a(href:HelpPage.routing) { "Would You Like to Know More?" }
  end
end
```

That means you can replace the file with this code.  Other times, we may only focus on one method.  We might write "Change `view_template` in `SomeComponent` so it looks like so:"

```ruby
def view_template
  h3 { "My component" }
  a(href:HelpPage.routing) { "Would You Like to Know More?" }
end
```

In this case, you'd replace the method, but the leave the rest of the class as-is.

On occasion we'll want to only change a few lines and, in that case, we'll use a diff format like so:

```diff
-     a(href: "") { "Write New Blog Post" }
+     a(href: BlogPostEditorPage.routing) { "Write New Blog Post" }
```

If a change is more complex, sometimes we'll show line numbers and highlight the changes.  Below, we're
showing a change to lines 14,15, and 16 of the file.

```ruby:line-numbers=12 {3-5}
  a(href: "BlogPostEditorPage.routing") do
    plain { "Edit" }
    span do
      inline_svg("edit_icon")
    end
  end
```

This says to find the line that looks like the first one (preceded with a `-` and shown in red) and replace it with the second one (preceded with a `+` and shown in green).  **Do not use the `+` or `-` in your code**, that is just to indicate which line is which.

Lastly, we'll try to mention the path to the file either in the preceding text or as a comment in the code.

## Tutorials

These go mostly in order, each building on the last, but you can start anywhere by using the tutorial on GitHub.  The only one that starts from nothing is the first one.

| Index | Title | Tutorial | Screencast |
| ---   | ---   | ---      | ---        |
| 1 | Build a Blog in 15 Minutes | [Tutorial](tutorials/01-intro) | [Screencast](https://video.hardlimit.com/w/ae7EMhwjDq9kSH5dqQ9swV) |
| 2 | Adding a Styled Confirmation Dialog | [Tutorial](tutorials/02-dialog) | [Screencast](https://video.hardlimit.com/w/4y8Pjd8VVPDK372mozCUdj) |
| 3 | Leveraging Externalizable IDs (coming soon) | |
| 4 | Form Basics (coming soon) | |
| 5 | Advanced Forms (coming soon) | |
| 6 | AJax Form Submissions (coming soon) | |
| 7 | Authentication (coming soon) | |
| 8 | Background Jobs with Sidekiq (coming soon) | |
| 9 | How to Leverage BrutJS and Custom Elements (coming soon) | |
