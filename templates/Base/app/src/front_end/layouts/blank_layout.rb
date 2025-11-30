# A blank layout that just renders whatever the page content is.
# This is useful for a page that can respond to Ajax and not want
# the surrounding HTML metadata.
class BlankLayout < Brut::FrontEnd::Layout
  include Brut::FrontEnd::Components

  def view_template
    yield
  end
end

