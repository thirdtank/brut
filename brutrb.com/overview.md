# Conceptual Overview

Brut is a way to build web apps that generate HTML, have JavaScript and CSS, and
interact with a Database. It's built on Ruby standard libraries and community
libraries like [Sequel](https://sequel.jeremyevans.net/) and
[Phlex](https://phlex.fun).

Brut's approach and design are built on three core values:

* **Leverage Standards** - The web platform is great, and Brut wants you to use it.
* **There's One Best Way To Do It** - Flexibility leads to chaos.
* **Simple over Easy** - Verbose code that can be quickly understood beats impenetrable compact DSLs every day.

Brut's abstractions tend to mirror concepts found in the domain of web sites. For
example, a browser serves up a web page at a URL. In Brut, that's called a *page*
and you'd create a subclass of `Brut::FrontEnd::Page` to implement it.

Brut tries to avoid abstractions that simply translate existing standards into a
more aestheticly pleasing form. You already need to know CSS, HTML, the Web
Platform, and SQL, so there's little to gain by requiring you to learn a different
way to use them.

## Basic Elements

Brut organizes its code and behavior around four basic concepts:

* **Client** or *Client Side* is the web browser (or HTTP client). This is where CSS is applied to HTML and where JavaScript is executed. HTTP requests are initiated here.
* **Server** or *Server Side* is where any code not in the browser runs. In Brut, this includes HTML generation, SQL queries, and everything in between.
* **Front End** is the code that deals with producing your user interface or HTTP API.  A lot of this code runs on
the *server side*, however it exists to provide a user interface of some sort.
* **Back End** is the code that deals with everything else, such as accessing a database, executing business logic, or managing background jobs.


![Architectural Overview](/images/OverviewMetro.png)

* **Visitor** is someone visiting your web site or app.
* **Browser** is, well, a web browser
* [**Pages**](/pages) generate web pages, which is what happens when a browser's UI navigates to a URL.
* [**Forms**](/forms) are submitted by the browser to the server. In Brut, a form describes the contents of a `<form>` as well as provides access to the submitted data.
* [**Handlers**](/handlers) receive non-GET HTTP requests from the browser, notably form submissions.
* [**Components**](/components) generate HTML fragments and are used to generate the HTML of a page or for re-use across pages.
* [**JavaScript**](/javascript) and [**Assets**](/assets) (including [CSS](/css)) are bundled on the server and sent to the client.
* [**Domain Logic**](/business-logic) as where your business and domain logic lives and can be implemented however you like.
* [**DB Models**](/database-access) are objects that provide access to your database.
* **Relational Database** is your database, where data is stored.

Brut doesn't prevent the addition of more pieces of infrastructure or code. You can
add a Redis cache, a Sidekiq job backend, or integrate with third party APIs.

## Brut is Not MVC

Brut is *not* an MVC framework, nor does it use the concept of *resources* as an
abstraction.  Although HTTP does include this concept, we find it's not as useful
for managing web apps as it may seem.

We've found that teams often struggle with mapping what everyone else calls pages
to resources and HTTP verbs.  We also find that the consonance features, resources, actions, and database tables never materializes.  We're basically not going to debate what the meaning of the `DELETE` verb on the `widgets` resource is actually supposed to mean.

## Brut is Hippocratic Licensed

It's important to me that Brut is used to make the world a better place. Please take
a not of [its license](https://firstdonoharm.dev/version/3/0/cl-eco-media-my-tal-xuar.txt)
