# The default layout used by Brut apps. Apps get a `DefaultLayout` subclass that
# sets the page title; override methods here or in that subclass to customize.
class Brut::FrontEnd::Layouts::Default < Brut::FrontEnd::Layout
  include Brut::FrontEnd::Components

  # The contents of the `<title>` element. Subclasses (such as an app's
  # `DefaultLayout`) are expected to override this.
  #
  # @return [String]
  def page_title = Brut.container.project_root.basename.to_s

  # The layout used by all pages.
  def view_template
    doctype
    html(lang: I18n.locale.to_s, dir: locale_rtl? ? "rtl" : "ltr") do
      head do
        meta(charset: "utf-8")
        meta(content: "width=device-width,initial-scale=1", name:"viewport")
        meta(content: "website", property:"og:type")
        # Sets this up as a PWA - see app/public/static/manifest.json
        link(rel: "manifest",  href: "/static/manifest.json")

        # Load the bundled stylesheet.  asset_path translates the logical
        # path to the hased value produced by esbuild
        link(rel: "preload", as: "style", href: asset_path("/css/styles.css"))
        link(rel: "stylesheet",           href: asset_path("/css/styles.css"))

        # Load the bundled JavaScript.  asset_path translates the logical
        # path to the hased value produced by esbuild
        script(defer: true, src: asset_path("/js/app.js"))

        title do
          plain(page_title)
        end

        # Brut::FrontEnd::Components::PageIdentifier, which produces
        # a <meta> tag with the page's name. Useful for end to end tests.
        # Does not generate anything in production.
        PageIdentifier(page)

      end
      # Adds the page's name as a class name. You can use this for
      # CSS if needed.
      body(class: page.page_name) do

        # Brut::FrontEnd::Components::I18nTranslations, which includes
        # translations starting with cv.cs for use with client-side
        # constraint violation messaging.
        I18nTranslations("cv.cs")
        # Brut::FrontEnd::Components::I18nTranslations, which includes
        # translations for cv.this_field, which is used with client-side
        # constraint violation messaging.
        I18nTranslations("cv.this_field")
        # Brut::FrontEnd::Components::Traceparent, which stores
        # the OpenTelemetry traceparent in a <meta> attribute for use
        # by the <brut-tracing> element.
        Traceparent()

        # Render the <brut-tracing> element, which will send
        # OpenTelemetry traces back to the server to be joined up with
        # the server's traces.
        brut_tracing url: "/__brut/instrumentation", show_warnings: true

        yield # Contents of the page are inserted here
      end
    end
  end
end
