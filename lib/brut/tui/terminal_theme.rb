# A terminal theme is a set of semantic styles for the terminal that
# map to actual colors or styles based on the terminal's metadata or
# the user's preferences or both.
#
# This class is coupled to the behavior of ANSI escape
# codes in the terminal, in that they aren't markup, but more
# like drawing with a pen.

# That said, this class' API does abstract from the codes
# themselves and creates a semantic layer, for example
# the definition of "succes" or "weak".

# For subclass implementors, there are various private
# methods that do encapsulate the ANSI escape codes, and these
# can be used or overridden.
#
# This particular implementation avoids the use of black or white, and uses
# the normal ANSI colors.  This should, in theory, work with any terminal
# theme where all colors are legible on the chosen background.
class Brut::TUI::TerminalTheme

  def self.based_on_background(terminal)
    if dark_background?(terminal)
      Brut::TUI::Themes::Dark.new(terminal)
    else
      Brut::TUI::Themes::Light.new(terminal)
    end
  end

  def self.dark_background?(terminal)
    r, g, b = terminal.background_color.map { it / 255.0 }
    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

    return luminance < 0.5  
  end

  def initialize(terminal)
    @terminal = terminal
  end

  # Returns a string with its markup turned into escape codes.
  # Note that due to the way ANSI escape codes work, the state
  # of the terminal may not be in the same state you found it.
  #
  # This method tries to turn features on and off (e.g. after a bold
  # string, the codes to turn off bold are applied), but if a subclass
  # mixes colors and styles, any text output after this one may
  # not look like the text before it.
  def with_markup(string, text: :normal, reset: true)
    result = +""
    result << send(text)
    Brut::TUI::MarkupString.from_string(string).parse do |directive, value|
      case directive
      in :start
        case value
        in :bold
          result << bold
        in :strike
          result << strike
        in :code
          result << code
        in :weak
          result << weak
        end
      in :stop
        case value
        in :bold
          result << bold_off << send(text)
        in :strike
          result << strike_off << send(text)
        in :code
          result << code_off << send(text)
        in :weak
          result << weak_off << send(text)
        end
      in :text
        result << value
      end
    end
    if reset
      result << self.reset
    end
    result
  end

  def success = bold + bright_green
  def error   = bold + bright_red
  def warning = bold + yellow

  def bold     = esc("1")
  def bold_off = normal

  def bright     = esc("1")
  def bright_off = normal

  def italic     = esc("3")
  def italic_off = esc("23")

  def strike     = esc("9")
  def strike_off = esc("29")

  def weak     = esc("2")
  def weak_off = normal

  def code     = underline
  def code_off = underline_off

  def normal = esc("22")

  def reset = esc("0")

  def heading = bold + underline + bright_blue

private

  def underline     = esc("4")
  def underline_off = esc("24")

  def black   = esc("30")
  def red     = esc("31")
  def green   = esc("32")
  def yellow  = esc("33")
  def blue    = esc("34")
  def magenta = esc("35")
  def cyan    = esc("36")
  def white   = esc("37")

  def bright_black   = esc("90")
  def bright_red     = esc("91")
  def bright_green   = esc("92")
  def bright_yellow  = esc("93")
  def bright_blue    = esc("94")
  def bright_magenta = esc("95")
  def bright_cyan    = esc("96")
  def bright_white   = esc("97")

  def esc(code)
    "\e[#{code}m"
  end
end
