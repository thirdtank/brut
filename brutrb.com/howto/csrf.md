# Custom CSRF Behavior

Brut allows you to change what POST requested require CSRF. By default, Brut
uses `Brut::FrontEnd::CsrfProtector` which requires CSRF for all POSTs.  You
can change this as follows:

1. Create a subclass of `Brut::FrontEnd::CsrfProtector`.  For simple use-cases,
   you can put this as an inner class of `App` (in `app/src/app.rb`). Here is
   an example that removers the requirement for `/webhooks/` to supply a CSRF
   token:

   ```ruby{5-13}
   class App < Brut::Framework::App

     # ...
     
     class CsrfProtector < Brut::FrontEnd::CsrfProtector
       def allowed?(env) # Brut will call this and 
                         # require CSRF if it returns true

         # env is a Rack env
        
         !!env["PATH_INFO"].to_s.match?(/^\/webhooks\//) 
       end
     end
     # ...
   end
   ```
2. Tell Brut to use your class instead of the default.  Inside the `initialize`
   method of `App` (in `app/src/app.rb`):

   ```ruby{5}
   def initialize

     # ...

     Brut.container.override("csrf_protector", CSRFProtector.new)

     # ...

   end
   ```
