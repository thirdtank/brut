# Why Does Brut Exist?

I love writing Ruby, but grew tired of writing Rails. Rails is great, and has been
great to me over the years. I've written a lot of books about it!  But the churn and
increasing configuration burden made me think: what if we had another way to build
web apps in Ruby?

I wanted something I felt was as easy and simple as Rails, but more accessible, more
obvious, and with fewer abstractions and DSLs.  Ruby and the web platform have come
a long way in the last several years and the community has created a lot of great
gems that can be used for a web framework.

My hope is that Brut can be a real alternative to Rails when creating web apps with Ruby. It doesn't need to be used by big huge companies. It probably shouldn't be!  It doesn't need to take you to an IPO.  But, it should allow building real, useful web apps using a great programming language!

## Brut is Not Rails

There's a lot of lessons in app design and framework design in Rails.  Brut
definitely takes some of the good ideas, but I started from scratch (ish) and
created abstractions only to solve a problem.  That's why there's no controllers, no
convoluted routing system, and no YAML.


## Brut is Not Hanami

Hanami has a lot of polish and great people working on it. But it's not designed the
way I wanted to work.  I find the DRY family of gems way too complicated for my
taste, and Hanami just felt overall too complex.  I'm sure there's a reason it is
the way it is, but it wasn't for me.

## Brut is Only Coincidentally Sinatra

Brut is built on Sinatra, however it's treated as a private implementation detail.
It was just the easiest way to bootstrap everything.  Brut will never be as low
level and flexible as Sinatra.

## Brut is Rack, The Web, and as Straightforward as Possible

Rack is great. The Web is great.  I tried to create abstractions only when needed
and to mirror existing abstractions as close as possible. It's a small thing, but I
have grown tired of typing `text_area` in Rails ERB files.  It's `textarea`, or at
least it should be.

My thinking is that you already need to know the web platform, HTML, CSS, SQL, and
the basics of HTTP.  Why learn an abstraction over those as well?

But I also didn't want to make everything myself.  Sequel is a great library! Phlex
is a great way to generate HTML!  RSpec is a great testing library!



