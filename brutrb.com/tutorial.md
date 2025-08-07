# Tutorial

Below, you'll build a blog that has a few pages, a form, a database table, and tests.   It's the same steps I took in the [15-minute blog video](https://video.hardlimit.com/w/ae7EMhwjDq9kSH5dqQ9swV).

If you'd just like to read source code, there are two apps you can check out:

* [The blog we'll build here](https://github.com/thirdtank/blog-demo)
* [ADRs.cloud](https://github.com/thirdtank/adrs.cloud), which is a more realistic app that has
  mulitple database tables, progressively-enhanced UI, and background jobs.

You can be running either of these locally in minutes as long as you have Docker installed.

## Set Up

The only two pieces of software you need are Docker and a code editor:

1. [Install Docker](https://docker.com)

   > [!TIP]
   > If you are on Windows, we *highly* recommend you use the 
   > Windows Subystem for Linux (WSL2), as this makes Brut, web developement,
   > and, honestly, your entire life as you know it, far easier than trying to
   > get things working natively in Windows.
2. Get a code editor like VSCode.  We don't use VSCode, but we are old and learned Vi/Vim/NeoVim when we were young.  If you have no code editor installed, Vi/Vim/NeoVim will be harder to get started, so use VSCode in this case.   

To test that Docker is working, open a terminal and we'll run a command using the `docker` command line app.

### Diversion: How to Understand the Command Line Invocations

If you aren't comfortable on the command line, it can be hard to understand what parts of this tutorial represent stuff you should type/paste and what is output from those commands.  Here is how that works.

For a command to run, the preceding text will tell you something like "run this command", and then you'll see a codeblock that has the label "bash" in the upper right corner, like so:

```bash
ls -l
```

If you hover over it, an icon witih the tooltip "Copy Code" will appear on the right, and you can click that to copy the command-line invocation. Or, you can select it and copy it, or you can type it in manually.

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

OK, back to your regularly-scheduled tutorial

### Verifying Docker is Installed

To check that docker is installed, open up a terminal and run:

```bash
docker info
```

This should produce a ton of output:

```
# OUTPUT
Client:
 Version:    28.2.2
«LOTS OF OUTPUT»
```

To be extra sure, **right after you ran `docker info`**, check `$?`, the exit code, to make sure it's a 0, which means the command ran successfully:

```bash
echo $?
```

```
# OUTPUT
0
```

Now, let's create the app by first initializing it.

## Initialize Your App

`mkbrut` is a command line app that will initialize your new app. It's available as a RubyGem or a Docker image.  We'll use the Docker image since that doesn't require installing anything.

We'll call the blog simply "blog". This is the only argument we need to give to `mkbrut`, although the command line to run it via Docker is pretty long.

`cd` to a folder where you'd like to work. `mkbrut` will create a folder called `blog` in there and in *that* folder, your app will be initialized.

```
docker run \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -u $(id -u):$(id -g) \
       -it \
       thirdtank/mkbrut \
       mkbrut --no-demo blog
```

You should see this output:

```
# OUTPUT
[ mkbrut ] Creating app with these options:
[ mkbrut ] App name:      blog
[ mkbrut ] App ID:        blog
[ mkbrut ] Prefix:        bl
[ mkbrut ] Organization:  blog
[ mkbrut ] Include demo?  true
[ mkbrut ] Creating Base app
[ mkbrut ] Creating segment: Bare bones framing
[ mkbrut ] blog was created

[ mkbrut ] Time to get building:
[ mkbrut ] 1. cd blog
[ mkbrut ] 2. dx/build
[ mkbrut ] 3. dx/start
[ mkbrut ] 4. [ in another terminal ] dx/exec bash
[ mkbrut ] 5. [ inside the Docker container ] bin/setup
[ mkbrut ] 6. [ inside the Docker container ] bin/dev
[ mkbrut ] 7. Visit http://localhost:6502 in your browser
[ mkbrut ] 8. [ inside the Docker container ] bin/setup help # to see more commands
```

Before we follow the instructions in the output, `cd` to `blog` and check it out.

```bash
cd blog
ls
```

```
#OUTPUT
app                    Dockerfile.dx  Procfile.development  specs
bin                    dx             Procfile.test         
config.ru              Gemfile        puma.config.rb        
docker-compose.dx.yml  package.json   README.md
```

* `app` is where all the code your app will be
* `bin` has command line  tools to manage your app
* `dx` has command line tools to manage your development environment
* `specs` is where your tests will go

OK, let's start up the dev environment:

```bash
dx/build
```

```
# OUTPUT
[ dx/build ] Could not find Gemfile.lock, which is needed to determine the playwright-ruby-client version
[ dx/build ] Assuming your app is brand-new, this should be OK
[+] Building 0.2s
«LOTS OF OUTPUT»
```

This may take a while, but it's building a Docker image where all your work will happen, although you'll be able to edit your code on your computer with the editor of your choice.

When this is done, we'll start up the dev environment:

```bash
dx/start
```

```
#OUTPUT
[ dx/start ] 🚀 Starting docker-compose.dx.yml
[+] Running 1/5
 ⠙ Container blog-postgres-1
 ⠙ Container blog-app-1
 ⠙ Container blog-otel-desktop-viewer-1
«LOTS OF OUTPUT»
```

This command won't stop, it'll keep running.  The first time it runs, it may take a while since it will be downloading Postgres and otel-desktop-viewer.  Postgres is your database and otel-desktop-viewer allows you to look at app telemetry in development.

Now, let's access the container we started.

Open a new terminal window, `cd` to where `blog` is, and use `dx/exec` to run `bash`, effectively "logging in" to the container:

```bash
dx/exec bash
```

```
# OUTPUT
[ dx/exec ] 🚂 Running 'ssh-agent bash' inside container with service name 'app'
Now using node v22.17.1 (npm v10.9.2)
docker-container - Projects/blog
> 
```

At that prompt, you can now type commands. If you type `ls`, you'll see the same files you saw when we ran it above:

```bash
ls
```

```
#OUTPUT
app                    Dockerfile.dx  Procfile.development  specs
bin                    dx             Procfile.test         
config.ru              Gemfile        puma.config.rb        
docker-compose.dx.yml  package.json   README.md
```

This is because the folder on your computer is synced to the one inside the container. Changes in one are immediately reflected in the other.

**From here on out, all command line invocations are run inside this container**, unless stated otherwise.

## Set Up the App Itself

`mkbrut` created a lot of files for you, as well as command line apps to manage your app.  We're going to perform app setup via `bin/setup`. This completely automates the following tasks:

* Installing RubyGems
* Installing Node Modules
* Installing Shopfiy's Ruby LSP, and Microsoft's JS and CSS LSPs
* Creating your dev and test databases
* Setting up Chromium, which we'll use to run end-to-end tests

Run it now (rememeber, this is inside the container, so you should've run `dx/exec bash` on your computer first)

```bash
bin/setup
```

```
# OUTPUT
[ bin/setup ] Installing gems
[ bin/setup ] Executing ["bundle check --no-color || bundle install --no-color --quiet"]
«LOTS OF OUTPUT»
```

When this is done, we can check that everything's working by running `bin/ci`.  `bin/ci` runs all tests and quality checks.  Even though you haven't written any code, there's just a bit included to demonstrate that things are working.  So there are a few tests.

```bash
bin/ci
```

```
# OUTPUT
[ bin/ci ] Building Assets
«LOTS OF OUTPUT»
[ bin/ci ] Running non E2E tests
«LOTS OF OUTPUT»
[ bin/ci ] Running JS tests
«LOTS OF OUTPUT»
[ bin/ci ] Running E2E tests
«LOTS OF OUTPUT»
[ bin/ci ] Analyzing Ruby gems for
«LOTS OF OUTPUT»
[ bin/ci ] security vulnerabilities
«LOTS OF OUTPUT»
[ bin/ci ] Checking to see that all classes have tests
«LOTS OF OUTPUT»
[ bin/ci ] Done
```

Finally, we'll run the app itself via `bin/dev`

```bash
bin/dev
```

`bin/dev` won't exit, it'll sit there running your app until you hit `Ctrl-C`.  Amongst the output you should see a message like:

```
# OUTPUT
« LOTS OF OUTPUT »
Your app is now running at

   http://localhost:6502

```

Go to http://localhost:6502 in your web browser.  You should see a welcome screen like so:

XXXX

## The Blog We'll Build

We're ready to write some code!  Here's how the blog is going to work:

* A blog post has a title and content, with each paragraph of the content separated with `\n\r`, which
is what the browser inserts when you hit return.
* The home page will show all the blog posts in reverse chronological order.
* The home page will link to the edit blog post page where a blog post can be created.
* Blog posts will be submitted to the backend to be saved, with the following constraints:
  - title and content are required
  - title must be at least three characters
  - content must be at least 5 words (i.e. space-separated tokens)

We'll discuss tests later.  To make it easier to follow Brut, we'll get things working first and then test them. You can absolutely do TDD with Brut, but we find it's hard to learn new things this way.

Let's start not from the database, but from the user experience.

## Building and Styling Pages

The home page of a Brut app is served, naturally, on `/` and is implemented by the class `HomePage`, located in `app/src/front_end/pages/home_page.rb`.

A *page* in Brut is a Phlex component that is rendered inside a layout. A layout is common markup that all pages should have, such as the `<head>` section and perhaps a `<body>` or other tags.  `mkbrut` provided a default layout that's good for now, so we just have to worry about the HTML that is specific to a page.

Open up `app/src/front_end/pages/home_page.rb` in your editor.  You should see something like this:

```ruby
class HomePage < AppPage
  def page_template
    # The duplication and excessive class sizes here are to
    # make it easier for you to remove this when you start working
    # on your app.  There are pros and cons to how this code
    # is written, so don't take this is as a directive on how to
    # build your app. You do you!
    img(src: "/static/images/LogoPylon.png",
        class: "dn db-ns pos-fixed top-0 left-0 h-100vh w-auto z-2")
  
    header(class: "flex flex-column items-center justify-center h-100vh") do

      # A lot more code

    end
  end
end
```

`page_template` is where you can call Phlex to generate HTML.  

> [!NOTE]
> Phlex components use `view_template`, and that's what
> components in Brut use, too.  Pages, however, use 
> `page_template` so that the HTML can be placed inside
> a layout. `page_template` is a Brut concept, not a Phlex one.

### Creating the HomePage

Delete all the code in `page_template` and replace it with this:

```ruby
def page_template
  header do
    h1 { "My Amazing Blog" }
    a(href: "") { "Write New Blog Post" }
  end
  main do
    p { "Posts go here" }
  end
end
```

If you've never used Phlex before, it's a Ruby API that defines one method for each HTML element (along with any custom elements you tell it about).  You then call these methods to build up markup. As you can see, it's structurally identical to HTML, but it's Ruby.

If your server is still running, refresh the page and you'll see this wonderful UI (otherwise, start your server with `bin/dev`):

XXXXX

Let's make it a bit nicer.

### Using CSS

Open up `app/src/front_end/css/index.css` in your editor.  You should see this:

```css
@import "brut-css/dist/brut.css";
@import "svgs.css";
```

Brut uses esbuild to bundle CSS. esbuild makes use of the standard `@import` directive.  All `@imports` are relative to the current file or to `node_modules`.  `brut-css/dist/brut.css` is the BrutCSS library that comes with Brut. We aren't going to use it, just to keep things focused.  `svgs.css` is located in `app/src/front_end/css/svgs.css` and sets up a few classes for inline SVGs.

We'll add some CSS for the home page right here.  We'll use vanilla CSS to avoid going on a deep dive on CSS frameworks.

Add this below `@import "svgs.css";`

```css
body {
  width: 50%;
  margin-left: auto;
  margin-right: auto;
}

header {
  border-bottom: solid thin gray;
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  width: 100%;
  gap: 0.5rem;
}
```

If you reload the home page in your browser, it now looks at least a little bit respectible:

XXXXX

Now, let's do the blog post editor.

## Creating Forms

To create blog posts, we need three things:

* A page where the creation happens, which will host an HTML `<form>`
* A URL where that `<form>` will be submitted
* Some code to handle the submissions

### Creating a New Page

To make a new page in Brut, we'll need to declare a route, and Brut will choose the class name.  We'll use `/blog_post_editor`, meaning Brut will expect `BlogPostEditorPage` to exist.  We can do all this at once with `bin/scaffold`, which you can run now like so:

```bash
bin/scaffold page /blog_post_editor
```

```
# OUTPUT
TBD
```

Before we look at the page, let's fix the link on the home page. If you recall, we set `href` to `""`.  While we could use `"/blog_post_editor"` as the URL, it's better to let Brut create routes.  Each page class has a class method called `routing` that will generate a URL to that page.

Open up `app/src/front_end/pages/home_page.rb` and make this change:

```diff
-     a(href: "") { "Write New Blog Post" }
+     a(href: BlogPostEditorPage.routing) { "Write New Blog Post" }
```

Although `BlogPostEditorPage` doesn't take any query string parameters or have any dynamic parts of its route, using `.routing` will be more consistent as the app grows.

With this change, you can now click the link and see the `BlogPostEditorPage`'s HTML:

XXXX

Before we change the HTML, we'll need to describe our form as a *form class*.  In Brut, forms are managed with classes, and they are provided to a *handler* which handles the submission and provides a response (like a controller in Rails, if you are familiar).

### Create a Form and Handler

A form gets submitted to a URL, and Brut routes that submission to a handler.  To create both a form class and a handler, we'll use `bin/scaffold form`, giving it the URL to respond on.

In this case, we'll use the URL `/new_blog_post`:

```bash
bin/scaffold form /new_blog_post
```

```
# OUTPUT
TBD
```

The form class that was just created, `NewBlogPostForm` (located in `app/src/front_end/forms/new_blog_post_form.rb`) can be used to generate HTML (after we declare the inputs it accepts), and hold the values submitted from the browser.

First, let's declare our inputs.  Open up `app/src/front_end/forms/new_blog_post_form.rb` and make it look like so:

```ruby
class NewBlogPostForm < AppForm
  input :title, minlength: 3
  input :content
end
```

Each field is required by default.  You can specify additional constraints using the same attributes you'd use on an `<input>` in HTML (this is why you see `minlength` above and not a more idiomatic `min_length` or even `min`—Brut tries to mirror the web platform when possible).

With these declarations, we can use an instance of this class to generate HTML.

### Generating an HTML Form

The `BlogPostEditorPage` will contain the form used to write a blog post.  This page must make sure two things happen:

* When someone navigates to it, it should show the form with nothing in the fields.
* When there is an error in what the blog post author has provided, it should show those errors, but
also maintain the inputs the author provided.

To do this, the `BlogPostEditorPage` will need an instance of `NewBlogPostForm`.  We can create this in its constructor. Open up `app/src/front_end/pages/blog_post_editor_page.rb` and start it off like so:

```ruby
class BlogPostEditorPage < AppPage

  def initialize
    @form = NewBlogPostForm.new
  end

  # ...

end
```

Next, we'll implement `page_template` and we'll use `@form` to create HTML for the form's inputs, including client-side constraints and, as we'll see later, pre-existing values from a previous submission.

This will require four parts of Brut's API and use one optional one:

* `brut_form`, a custom element (`<brut-form>`) that will progressively enhance the form to provide
constraint violation visitor experience if JavaScript is enabled.
* `FormTag`, a Phlex component provided by Brut that generates the correct `<form>` element, as well as
CSRF protection.
* `Inputs::` components, namely `Inputs::InputTag` and `Inputs::TextareaTag`, which generate `<input>`
and `<textarea>`, respectively. This Phlex components (provided by Brut) will add the correct attributes for validation, and set the values if the form they are given has values set.
* `ConstraintViolations`, a Phlex component provided by Brut that generates custom elements that, when
JavaScript is enabled, allow for control over the visitor experience when there are constraint violations.
* *(optional)* `t` provides access to localized strings, instead of hard-coding English.

Create `page_template` to look like so:

```ruby
def page_template
  h1 { t(:write_new_post) }
  brut_form do
    FormTag(for: @form) do
      label do
        Inputs::InputTag(form: @form,input_name: :title, autofocus: true)
        div { t([:form, :title]) }
        ConstraintViolations(form: @form, input_name: :title)
      end
      label do
        Inputs::TextareaTag(form: @form,input_name: :content, rows: 10)
        div { t([:form, :content] ) }
        ConstraintViolations(form: @form, input_name: :content)
      end

      button { t([:form, :post]) }
    end
  end
end
```

If you reload the page now, you'll get an error about missing translation keys.  Let's add those.


### Adding Translation Keys

In Brut, translations aren't stored in YAML, but in a Ruby hash.  Brut provides standard translations in `app/config/i18n/en/1_defaults.rb`, but your app will set its own in `app/config/i18n/en/2_app.rb`:

```ruby
# All app-specific translations, or overrides of Brut's defaults, go here.
{
  # en: must be the first entry, thus indicating this is the EN translations
  en: {
    cv: {
      cs: {
      },
      ss: {
        email_taken: "This email has been taken",
      },
    },
    pages: { # Page-specific messages - this key is relied-upon by Brut to exist
      HomePage: {
        title: "Welcome!",
      },
      BlogPostEditorPage: {
        title: "BlogPostEditorPage"
      },
    },
    # ... more code
```

When you use `t` on a page in Brut, it looks for `pages.«page name».«key»`, so Brut needs from our form:

* `pages.BlogPostEditorPage.write_new_post`
* `pages.BlogPostEditorPage.form.title`
* `pages.BlogPostEditorPage.form.content`
* `pages.BlogPostEditorPage.form.post`

Give them values like so:

```ruby
# All app-specific translations, or overrides of Brut's defaults, go here.
{
  # en: must be the first entry, thus indicating this is the EN translations
  en: {
    cv: {
      cs: {
      },
      ss: {
        email_taken: "This email has been taken",
      },
    },
    pages: { # Page-specific messages - this key is relied-upon by Brut to exist
      HomePage: {
        title: "Welcome!",
      },
      BlogPostEditorPage: {
        title: "BlogPostEditorPage"
        write_new_post: "Write a new post!",
        form: {
          title: "Title",
          content: "Post Content",
          post: "Post It!",
        }
      },
    },
    # ... more code
```

Now, when you reload the page, it should work:

XXXX

Without filling anything in, click the submit button. The form should show you some error messages that are unstyled:

XXXX

Let's style them and learn about how the `<brut-cv>` tags created by `ConstraintViolations` work.

### Styling Constraint Violations

If you view source, you should see HTML like so:

```html
<brut-cv-messages input-name='title'>
</brut-cv-messages>
```

If you click submit and view source, you'll see something like this:

```html
<brut-cv-messages input-name='title'>
  <brut-cv>This field is required</brut-cv>
</brut-cv-messages>
```

This was inserted by `<brut-form>` whenever an element of the form is invalid.  This could happen before the visitor clicks "submit", however.  To allow you to style these elements only when a submit has been attempted, `<brut-form>` will set the attribute `submitted-invalid` on itself when this happens.

Open `app/src/front_end/css/index.css` in your editor.  We want `<brut-cv>` messages to be red, bold, and in the body font size.  We also want them hidden by default.

```css
brut-cv {
  display: none;
  color: #A60053;
  font-weight: bold;
  font-size: 1rem;
}
```

When `submitted-invalid` is set on `brut-form`, *then* we show them.  We *also* want to show them if they were generated from the server, which `ConstraintViolations` will do:

```css
brut-form[submitted-invalid] brut-cv,
                             brut-cv[server-side] {
  display: block;
}
```

Let's also do some styling for the form and its elements.  Add this below the CSS you just wrote:

```css
.BlogPostEditorPage {
  brut-form {
    display: block;
    padding: 1rem;
    border: solid thin gray;
    border-radius: 0.25rem;
    background-color: #eeeeee;

    form {
      display: flex;
      flex-direction: column;
      gap: 1rem;
      align-items: start;
    }

    input, textarea {
      width: 100%;
      padding: 0.5rem;
      font-size: 130%;
    }
    label {
      width: 100%;
      font-size: 120%;
      display: block;
      div {
        font-weight: bold;
        font-style: italic;
      }
    }
    button {
      padding-left: 2rem;
      padding-right: 2rem;
      padding-top: 1rem;
      padding-bottom: 1rem;
      background-color: #E5FFE5;
      border: solid thin #006300;
      color: #006300;
      border-radius: 1rem;
      font-size: 150%;
      align-self: end;
      cursor: pointer;
      &:hover {
        background-color: #ACFFAC;
      }
    }
  }
}
``` 

Two notes about this CSS:

* It's using nesting, which is part of Baseline
* We've nested all the CSS inside the `.BlogPostEditorPage` class. The default layout Brut provides
includes this:

  ```ruby
  body(class: @page_name) do
    yield
  end
  ```
  
  This means all pages have their page name set on the `<body>` tag, allowing nested CSS, if you like.

*Now*, if you submit the form without providing any values, you'll see a decent-looking experience:

XXXX

If you fill out the fields correctly, you should see an error that you need to implement your handler.  Let's do that next.

## Handling Form Submissions

When you ran `bin/scaffold form` earlier, it created `NewBlogPostHandler`.  It's located in `app/src/front_end/handlers/new_blog_post_handler.rb`, which should look like so:

```ruby
class NewBlogPostHandler < AppHandler
  def initialize(form:)
    @form = form
  end

  def handle
    raise "You need to implement your handler"
  end
end
```

The `handle` method is expected to return a value that tells Brut how to respond to a form submission. In our case, we'll either want it to re-generate `BlogPostEditorPage`'s HTML with error messages and the visitor-supplied form fields pre-filled in, or save the blog post and redirect back to `HomePage`.

To do that, we'll either return an instance of `BlogPostEditorPage`, or return a `URI` to `HomePage` (which we can do with the helper method `redirect_to`).

Before `handle` is called, `NewBlogPostHandler` will be initialized and give an instance of `NewBlogPostForm` containing whatever data was submitted by the browser.  `handle` can then use `@form` to determine what to do.

First, we'll re-check client-side validations by calling `.valid?`. If that's true, we can perform server-side validations, calling `server_side_constraint_violation` for any violations we find.  Then, we'll check `.valid?` again and return a `BlogPostEditorPage` or redirect.

```ruby
class NewBlogPostHandler < AppHandler
  def initialize(form:)
    @form = form
  end

  def handle
    if @form.valid?
      if @form.content.split(/\s/).length < 5
        @form.server_side_constraint_violation(
          input_name: :content,
          key: :not_enough_words,
          context: { num_words: 5 }
        )
      end
    end
    if @form.valid?
      # TODO: Actually save the post
      redirect_to(HomePage)
    else
      BlogPostEditorPage.new(form: @form)
    end
  end
end
```

Of course, `BlogPostEditorPage` does not accept the form as a paramter.  We'll need to change that:

```ruby
class BlogPostEditorPage < AppPage

  def initialize(form: nil)
    @form = form || NewBlogPostForm.new
  end
```

With this in place, create a new blog post but with only four words in the content. This will pass client-side checks, but fail server-side checks. When you submit, you'll see an error related to `cv.ss.not_enough_words`, which is the key Brut is trying to use to find the actual error message.

Add it to `app/config/i18n/en/2_app.rb`, under `en`, `cv` (for constraint violations), `ss` (for server-side):

```ruby
# All app-specific translations, or overrides of Brut's defaults, go here.
{
  # en: must be the first entry, thus indicating this is the EN translations
  en: {
    cv: {
      cs: {
      },
      ss: {
        email_taken: "This email has been taken",
        not_enough_words: "%{field} does not have enough words. Must have %{num_words}",
      },
    },
```

*Now*, try again, and you'll see this message, rendered exactly like client-side errors:

XXXX

Now that we have the user experience in place, let's actually store the blog post in the database.

## Using a Database

Brut uses Postgres, and you can access your database using the Sequel library.  The class you'll create to access a table is called a *database model*, and to create one, you'll want to make a few changes to the app:

* Create a migration that creates the schema for the new table.
* Create the database model class itself.
* Create a FactoryBot factory that can create sample instances of rows in the table, useful for testing and development
* Modify seed data to create sample data for development.

Most of this can be done via `bin/scaffold db_model`.

### Creating a New Database Table

Run `bin/scaffold` like so:

```bash
bin/scaffold db_model blog_post
```

```
# OUTPUT
TBD
```

This created a migration file in `app/src/back_end/data_models/migrations`, named something like `20250801120000_blog_post.rb`.  The numbers in the name are a timestamp, so yours will be different.

Open that file in your editor and use `create_table`, as provided by Sequel, to describe the table:

```ruby
Sequel.migration do
  up do
    create_table :blog_posts,
                  comment: "All the posts fit to post",
                  external_id: true do
      column :title, :text
      column :content, :text
    end
  end
end
```

`up` is a method from Sequel that accepts a block to run when making a change to the schema. Sequel supports `down` which can undo that change, but Brut apps do need to use this.

Inside the block given to `up`, `create_table` creates a new table. *It* is given a block in which the schema of that table is defined.  All tables require a comment, and the `external_id:` option will create a unique externalizable key for our table that is managed separate from the table's primary key.

Inside the block given to `create_table` we call `column` twice to define our two columns.  Neither column is nullable. In Brut, database columns may not contain null by default. You can specify `null: true` to any column that is allowed null values.

Save this file, then apply this migration to your development database:

```bash
bin/db migrate
```

```
# OUTPUT
TBD
```

Now, apply it to your test database:

```bash
bin/db migrate -e test
```

```
# OUTPUT
TBD
```

You can examine the table that was created by running `bin/dbconsole`:

```bash
bin/dbconsole
```

```
# OUTPUT
psql (16.9 (Debian 16.9-1.pgdg120+1), server 16.4 (Debian 16.4-1.pgdg120+2))
Type "help" for help.

blog_development=#
```

This will give you a new prompt where you can type commands to `psql`, the Postgres command-line client.  Try describing the table:

```bash
\d+ blog_posts
```

```
# OUTPUT
TBD
```

`bin/scaffold` created the database model for you in `app/src/back_end/data_models/db/blog_post.rb`:

```ruby
class DB::BlogPost < AppDataModel
  has_external_id :bl
end
```

In Brut, database models are in the `DB::` namespace, so you do not need to conflate them with a *domain* model.

Note `has_external_id`.  Brut chose this value, and it will be used to create a second identifier for blog posts.  Those identifiers are prefixed with the app prefix (`bl` in this case) and then the model prefix (also `bl`). An example would be `blbl_9783245789345789345789345`.

These ids can be shared, and when you see one, you'll know that the first two characters being `bl` indicate the id is from your app. The next two characters being `bl` indicate its the ID of a blog post.

Let's change it to be `bp` just to avoid any confusiong with the app prefix:

```ruby
class DB::BlogPost < AppDataModel
  has_external_id :bp
end
```

Before we use this database model, we want to be able to create instances in tests, as well as for local development.  The way to do that in Brut is to create a factory.

### Creating Test and Development Data

Brut uses FactoryBot to create sample instance of your data.  Open up `specs/factories/db/blog_post.factory.rb` in your editor.

If you are new to FactoryBot, it is a lightweight (ish) DSL that allows creating test data.  You'll call methods based on the column names in order to specify values.  Brut also includes Faker, which creates randomized but realistic test data.

For the title, we'll use Faker's "hipster ipsum". For the content, we want several paragraphs delineated by `\n\r`, so we'll create between 2 and 6 paragraphs and join them.

Add code to `specs/factories/db/blog_post.factory.rb` to look like so:

```ruby
FactoryBot.define do
  factory :blog_post, class: "DB::BlogPost" do
    title { Faker::Hipster.sentence }
    content {
      (rand(4) + 2).times.map {
       Faker::Hipster.paragraph_by_chars(characters: 200)
      }.join("\n\r")
    }
  end
end
```

Brut includes a test to make sure your factories are valid and will work.  It's in `specs/lint_factories.spec.rb`.  Run it now to make sure this factory works:

```bash
bin/test run specs/lint_factories.spec.rb
```

```
# OUTPUT
TBD
```

Now, we can use this for seed data in development.  Edit `app/src/back_end/data_models/seed/seed_data.rb`, and add the following code, which will create 10 blog posts:

```ruby
require "brut/back_end/seed_data"
class SeedData < Brut::BackEnd::SeedData
  include FactoryBot::Syntax::Methods
  def seed!
    10.times do |i|
      create(:blog_post, created_at: Date.today - i)
    end
  end
end
```

`create` is a method provided by Factory Bot that is brought in via `FactoryBot::Syntax::Methods`.

Now, load the seed data into the development database with `bin/db seed`:

```bash
bin/db seed
```

```
# OUTPUT
TBD
```

Now, let's use this to show our blog posts and create new ones.

## Accessing the Database

On `HomePage`, we put in a `<p>` as a placeholder for blog posts.  Let's replace that with code to fetch and display the blog posts.

In Brut, since HTML is generated by Phlex and thus by Ruby code, we can structure our HTML generation however we like, including by accessing the database directly.  This may not scale as our app gets large, but for now, it's the simplest thing to do.

Sequel's database models are similar to Rails' Active Record's in that we can call class methods to access data. In this case, `DB::BlogPost` has a method `order` that will fetch all records sorted by the field we give it in the order we decide. The sort field and order is specified via `Sequel.desc` for descining or `Sequel.asc` for ascending. We want posts in reverse-chronological order, so `Sequel.desc(:created_at)` will achieve this.

We can call `.each` on the result and iterate over each blog post.  Here's what `page_template` should look like now:

```ruby
def page_template
  header do
    h1 { "My Amazing Blog" }
    a(href: "") { "Write New Blog Post" }
  end
  main do
    DB::BlogPost.order(Sequel.desc(:created_at)).each do |blog_post|
      article do
        h2 { blog_post.title }
        blog_post.content.split(/\n\r/).each do |paragraph|
          p { paragraph }
        end
      end
      hr
    end
  end
end
```

Start your server if you stopped it before. Go to the home page, and you should see our fake blog posts:

XXXX

To create rows in the database, the class method `create` can be called on `DB::BlogPost`, so lets change the handler to use that.  Open up `app/src/front_end/handlers/new_blog_post_handler.rb` and make `handle` look like so:

```ruby
def handle
  if !@form.constraint_violations?
    if @form.content.split(/\s/).length < 5
      @form.server_side_constraint_violation(
        input_name: :content,
        key: :not_enough_words,
        context: { num_words: 5 }
      )
    end
  end
  if @form.valid?
    DB::BlogPost.create(      # <----
      title: @form.title,     # <----
      content: @form.content  # <----
    )                         # <----
    redirect_to(HomePage)
  else
    NewBlogPostPage.new(form: @form)
  end
end
```

The form object provides access to the values of any field we've declared via a method call.

Now, create a new blog post, provide valid data, and submit it. You should be taken to `HomePage` with your blog post at the top!

Our work isn't quite done. We need tests.

## Testing Brut Apps

We'll create the following tests:

* Check that the logic in the handler is sound
* Check that blog posts show up on the home page
* Check that the entire workflow of create a blog post and seeing it show up on the home page works in a
real web browser

Let's test our handler first, as that is where the main logic is.

### Testing Handlers

Our handler will need three tests:

* If the form was submitted without client-side validations happening, we should not create a new blog
post and re-generate the blog post editor page, showing the errors.
* If client-side validations pass, but the blog post isn't five words or more, we should not create a
new blog post and re-generate the blog post editor page, showing the errors.
* If everything looks good, we save the new blog post and redirect to the home page.

Brut apps are tested with RSpec, and Brut provides several convienience methods and matchers to make testing as painless as possible.

When testing a handler, the public method is `handle!`, not `handle`, so we want to call that (Brut implements `handle!` to call `handle`).

First, we'll test client-side validations. Open up `specs/front_end/handlers/new_blog_post_handler.spec.rb` and replace the code there with this:

```ruby
require "spec_helper"

RSpec.describe NewBlogPostHandler do
  describe "#handle!" do
    context "client-side violations got to the server" do
      it "re-generates the HTML for the BlogPostEditorPage" do
        form  = NewBlogPostForm.new(params: {})

        result = described_class.new(form:).handle!

        expect(result).to have_generated(BlogPostEditorPage)
        expect(form).to have_constraint_violation(:title, key: :valueMissing)
        expect(form).to have_constraint_violation(:content, key: :valueMissing)
      end
    end
  end
end
```

`have_generated` asserts that the value returned from `handle!` is an instance of the page given, `BlogPostEditorPage` in this case.  You could just as easily write `expect(result.kind_of?(BlogPostEditorPage)).to eq(true)`, but `have_generated` expressed the intent of what's happening.

`have_constraint_violation` checks that form's `constraint_violations` contains one for the given field and the given key.  In this case, we check both `:title` and `:content` for `:valueMissing`.  This key is used because it's the value in the web platform's `ValidityState` for when a required value is missing.  Brut re-uses names and symbols from the web platform where it makes sense.

Next, we'll check that the server-side constraint violations are being checked. Add this just below the `context` you just added:

```ruby
context "post is not enough words" do
  it "re-generates the HTML for the BlogPostEditorPage, with server-side errors indicated" do
    form  = NewBlogPostForm.new(params: {
      title: "What a great post",
      content: "Not enough words",
    })

    confidence_check { expect(form.constraint_violations?).to eq(false) }

    result = described_class.new(form:).handle!

    expect(result).to have_generated(BlogPostEditorPage)
    expect(form).to have_constraint_violation(:content, key: :not_enough_words)
  end
end
```

This test introduces two new concepts:

* To initialize a form with data, you must pass a `Hash` to the keyword argument `params:`.  If the
`Hash` contains parameters that the form doesn't recognize, they are ignored and discarded.
* Since we are assuming there are no client-side constraint violations, we can check that the form has
none by calling `constraint_violations?` and checking that it returns false.  Since this is not part of the test, but a confidence check that our test setup is correct, this is wrapped in `confidence_check { ... }`, which will produce a different error message than if a test fails.

Lastly, we'll check that everything worked when there aren't any constraint violations. Add this below the `context` you just added:

```ruby
context "post is good!" do
  it "saves the post and redirects to the HomePage" do
    form  = NewBlogPostForm.new(params: {
      title: "What a great post",
      content: "This post is the best post that has been written in the history of posts",
    })

    confidence_check { expect(form.constraint_violations?).to eq(false) }

    result = nil
    expect {
      result = described_class.new(form:).handle!
    }.to change { DB::BlogPost.count }.by(1)

    expect(result).to have_redirected_to(HomePage)

    blog_post = DB::BlogPost.last
    expect(blog_post.title).to   eq("What a great post")
    expect(blog_post.content).to eq("This post is the best post that has been written in the history of posts")

  end
end
```

This is using RSpec's `expect { ... }.to change { ... }.by(N)` to make sure that our handler created a row in the database.  We then use the matcher `have_redirected_to` to assert that `result` is a URI to `HomePage`. We also check that the blog post we created in the database is correct.

Let's run the test with `bin/test run`

```bash
bin/test run specs/front_end/handlers/new_blog_post_handler.spec.rb
```

```
# OUTPUT
TBD
```

It passes!

Next, let's test `HomePage`.

### Testing Pages

Unlike our handler, which accepts arguments and returns a result, pages generate HTML.  We are better off testing pages by asking them to generate HTML and then examine the HTML directly.

Brut provides the method `generate_and_parse` to generate a page's HTML, then use Nokogiri to parse it. We can use CSS selectors on the result to assert things about the HTML.

`mkbrut` created `specs/front_end/pages/home_page.spec.rb`, so let's open that up on your editor.

The way we'll write this test is to generate four random blog posts using our factory, request the page, then assert that each blog post is on the page.  Rather than assert that each blog post's text is just somewhere on the page, we'll make use of the `external_id` concept. We'll use it as the `id` attribute of the `<article>`.

Here's the test:

```ruby
require "spec_helper"

RSpec.describe HomePage do
  it "should show the blog posts" do

    blog_posts = 4.times.map { create(:blog_post) }

    result = generate_and_parse(described_class.new)

    expect(result.e!("h1").text).to eq("Dave's Exicting Information")

    blog_posts.each do |blog_post|
      post_article = result.e!("article##{blog_post.external_id}")
      expect(post_article.e!("h2").text).to eq(blog_post.title)
      blog_post.content.split(/\n\r/).each do |paragraph|
        expect(post_article.text).to include(paragraph)
      end
    end
  end
end
```

The value returned from `generate_and_parse` responds to the Brut-provided `e!` which accepts a CSS selector that must return exactly one match, or the test fails.  It returns a Nokogiri node, where `.text` returns the equivalent of `innerContent`.

Let's run the test, which should fail:

```bash
bin/test run specs/front_end/handlers/new_blog_post_handler.spec.rb
```

```
# OUTPUT
TBD
```

To make it pass, we'll need to add `id:` to each `<article>`.  Make this one-line change in `HomePage`:

```diff
-      article do
+      article(id: blog_post.external_id) do
```

Now, the test should pass:

```bash
bin/test run specs/front_end/handlers/new_blog_post_handler.spec.rb
```

```
# OUTPUT
TBD
```

For `BlogPostEditorPage`, there really isn't anything to test - it's static HTML at this point.  Even still, it's good to record a decision about testing code or not, so it's clear we didn't just forget.  Brut provides the method `implementation_is_covered_by_other_tests` to do just that. It accepts a string where we can describe where the coverage for this class is.

In our case, it's going to be covered by an end-to-end test we'll write next.

Open  up `specs/front_end/pages/blog_post_editor_page.spec.rb` and make it look like so:

```ruby
require "spec_helper"

RSpec.describe BlogPostEditorPage do
  implementation_is_covered_by_other_tests "end-to-end test"
end
```

Now, all unit tests should pass, which we can check via `bin/test run`:

```bash
bin/test run
```

```
# OUTPUT
TBD
```

As our last test, we'll write an end-to-end that uses a browser.

### Writing Browser End-to-End Tests

Browser tests are expensive and slow, but it's good to test entire workflows that catch issues that a unit test might not.  In this case, we want to go through the steps of writing a blog post:

1. Go to the post editor page and make sure client-side validations show us errors.
2. Submit a post that's too short and make sure server-side errors show up.
3. Submit a valid post and check that it makes it back to the home page.

Brut uses Playwright to author end to end tests. Playwright is written in JavaScript, but there is a Ruby wrapper library that alleviates us from having to worry about async/await style coding.

Unfortunatley, Playwright's method of locating HTML elements and making assertions about them is different from Nokogiri's and from the web platform. Such is life.

The way this test will work is that we'll use `HomePage.routing` to kick everything off, find a link to `BlogPostEditorPage.routing`, then use Playwright's `page.locator` to find elements on the page to interact with.  Form fields respond to `fill` to put text in them, and buttons respond to `click`.  The matcher `have_text` can assert that text appears inside an element.

Brut provides the matcher `be_page_for` to assert that we are viewing the page we think we are. Nothing is more frustrating than watching assertions fail because your test ended up on the wrong page.

Open up `specs/e2e/home_page.spec.rb` and replace it with this:

```ruby
require "spec_helper"

RSpec.describe "Posting blog posts" do
  it "allows posting a post" do

    # 1. Go to the blog post editor page from the home page
    page.goto(HomePage.routing)
    new_post_link = page.locator("a[href='#{BlogPostEditorPage.routing}']")
    new_post_link.click

    expect(page).to be_page_for(BlogPostEditorPage)

    # 2. Provide data that violates client-side constraints and check for error messages
    title_field   = page.locator("brut-form input[name='title']")
    content_field = page.locator("brut-form textarea[name='content']")

    title_field.fill("XX")

    submit_button = page.locator("brut-form button")
    submit_button.click

    expect(page).to be_page_for(BlogPostEditorPage)

    title_error_message   = page.locator("brut-cv-messages[input-name='title'] brut-cv")
    content_error_message = page.locator("brut-cv-messages[input-name='content'] brut-cv")

    expect(title_error_message).to   have_text("This field is too short")
    expect(content_error_message).to have_text("This field is required")

    # 3. Provide data that passes client-side constraints but violates server-side ones
    title_field.fill("New blog post")
    content_field.fill("Too short")

    submit_button.click

    expect(page).to be_page_for(BlogPostEditorPage)

    expect(content_error_message).to have_text("This field does not have enough words")

    # 4. Provide a valid blog post
    content_field.fill("This is a longer post, so we should be OK")

    submit_button.click
    expect(page).to be_page_for(HomePage)

    new_post = DB::BlogPost.order(Sequel.desc(:created_at)).first

    article = page.locator("article##{new_post.external_id}")

    expect(article).to have_text("New blog post")
    expect(article).to have_text("This is a longer post, so we should be OK")

  end
end
```

Run it now with `bin/test e2e`:

```bash
bin/test e2e
```

It should pass:

```
# OUTPUT
TBD
```

With that test done, `bin/ci`, which we ran at the start, should run all tests, plus check for CVEs in our installed gems.

```bash
bin/ci
```

It should also pass:

```
#OUTPUT
TBD
```

That's it!

## Areas for Self-Exploration

Here are a few enhancement you can try to make:

* Create a client-side constraint requiring the title to match a certain regexp.
* Add a server-side constraint requiring at least two paragraphs.
* Allow editing the blog post creation date
* Add an author field to allow entering the author's name
* Add pagination to the home page
