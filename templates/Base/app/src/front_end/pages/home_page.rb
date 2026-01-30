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
      div(class: "flex flex-column flex-row-ns items-center justify-center gap-3") do
        img(src: "/static/images/LogoTransit.png", class: "h-5")
        div do
          h1(class: "ff-sans ma-0 lh-title f-5 tc tl-ns flex flex-column flex-row-ns items-center gap-2") do
            plain("Welcome to Brut")
          end
          h2(class: "ff-sans ma-0 lh-title f-3 fw-normal tc tl-ns") do
            plain("v")
            plain(Gem.loaded_specs["brut"].version.to_s)
          end

        end
      end
          nav(class: [ "ff-sans",
                       "flex",
                       "flex-column",
                       "flex-row-ns",
                       "items-center",
                       "justify-start",
                       "gap-3",
                       "mt-3",
          ]) do
            a(href: "https://brutrb.com",
              target: "_blank",
              class: "f-3 red-300 tdu tdn-ns hover-tdu-ns"
             ) do
               code { "brutrb.com" }
             end
             span(role: "separator", class: "dn di-ns f-3 red-300") do
                raw(safe "&#x2299;")
             end
             a(href: "https://brutrb.com/api/index.html",
               target: "_blank",
               class: "f-3 red-300 tdu tdn-ns hover-tdu-ns"
              ) do
                "API Docs"
              end
              span(role: "separator", class: "dn di-ns f-3 red-300") do
                raw(safe "&#x2299;")
              end
              a(href: "http://localhost:6504",
                target: "_blank",
                class: "f-3 red-300 tdu tdn-ns hover-tdu-ns"
               ) do
                 "Local OpenTelemetry"
               end
          end
    end
    
  end
end
