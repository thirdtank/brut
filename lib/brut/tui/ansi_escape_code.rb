# Maps ANSI escape codes to logical names to make it easier to use in code.
# This is not intended to be exhaustive, but could grow over time as needed.
class Brut::TUI::AnsiEscapeCode

  attr_reader :name

  # Create a new AnsiEscapeCode with the given name and code.
  #
  # @param name [String, Symbol] The logical name of the escape code.
  #                              This should not have spaces and generally be able to be used as a Ruby identifier.
  # @param code [String] The actual ANSI escape code (without the leading `\e[` and trailing `m`).
  def initialize(name, code)
    @name = name.to_sym
    @code = code
  end

  # Returns the code suitable for sending to the terminal.
  def to_s = "\e[#{@code}m"

  # Defines methods for each known code.  This module can be included
  # into other classes so you can write `self.ansi.bright_blue` (e.g.)
  # Note that `Brut::TUI::AnsiEscapeCode` _extends_ this module so you
  # can always do `Brut::TUI::AnsiEscapeCode.ansi.bright_blue`.
  module Mod
    CODES = [
      Brut::TUI::AnsiEscapeCode.new("reset"         , "0")  ,
      Brut::TUI::AnsiEscapeCode.new("bold"          , "1")  ,
      Brut::TUI::AnsiEscapeCode.new("normal"        , "22") ,
      Brut::TUI::AnsiEscapeCode.new("italic"        , "3")  ,
      Brut::TUI::AnsiEscapeCode.new("italic_off"    , "23") ,
      Brut::TUI::AnsiEscapeCode.new("strike"        , "9")  ,
      Brut::TUI::AnsiEscapeCode.new("strike_off"    , "29") ,
      Brut::TUI::AnsiEscapeCode.new("weak"          , "2")  ,
      Brut::TUI::AnsiEscapeCode.new("underline"     , "4")  ,
      Brut::TUI::AnsiEscapeCode.new("underline_off" , "24") ,
      Brut::TUI::AnsiEscapeCode.new("overline"      , "53") ,
      Brut::TUI::AnsiEscapeCode.new("overline_off"  , "55") ,
      Brut::TUI::AnsiEscapeCode.new("black"         , "30") ,
      Brut::TUI::AnsiEscapeCode.new("red"           , "31") ,
      Brut::TUI::AnsiEscapeCode.new("green"         , "32") ,
      Brut::TUI::AnsiEscapeCode.new("yellow"        , "33") ,
      Brut::TUI::AnsiEscapeCode.new("blue"          , "34") ,
      Brut::TUI::AnsiEscapeCode.new("magenta"       , "35") ,
      Brut::TUI::AnsiEscapeCode.new("cyan"          , "36") ,
      Brut::TUI::AnsiEscapeCode.new("white"         , "37") ,
      Brut::TUI::AnsiEscapeCode.new("bright_black"  , "90") ,
      Brut::TUI::AnsiEscapeCode.new("bright_red"    , "91") ,
      Brut::TUI::AnsiEscapeCode.new("bright_green"  , "92") ,
      Brut::TUI::AnsiEscapeCode.new("bright_yellow" , "93") ,
      Brut::TUI::AnsiEscapeCode.new("bright_blue"   , "94") ,
      Brut::TUI::AnsiEscapeCode.new("bright_magenta", "95") ,
      Brut::TUI::AnsiEscapeCode.new("bright_cyan"   , "96") ,
      Brut::TUI::AnsiEscapeCode.new("bright_white"  , "97") , 
    ].map { [ it.name, it ] }.to_h.freeze

    # The object returned by `#ansi` that has all the dynamically-defined methods
    # on it.  Generally don't call this method directly.
    def object
      @object ||= begin
                    object = Object.new
                    CODES.each do |name, code|
                      object.define_singleton_method(name) do
                        code
                      end
                    end
                    object
                  end
    end

    # Method for accessing the pre-defined ANSI escape codes.  This method
    # works in two ways: RGB mode and predefined mode based on the arguments passed.
    #
    # @param name [String|Symbol|Array<Integer>] If called with no arguments, return `#object`, allowing you to call
    #        a dynamically-defined method based on the AnsiEscapeCode names in `CODES`.
    #        If called with a String or Symbol, will return the AnsiEscapeCode for that name from `CODES`.
    #        Otherwise, this should be exactly three integers, each between 0 and 255 that
    #        represent red, green, and blue, respectively. In this case, the ANSI escape code
    #        for an RGB value is returned.
    # @return [Object|Brut::TUI::AnsiEscapeCode] The corresponding ANSI escape code object or the special `#object`.
    #
    # @example Using predefined codes
    #   Brut::TUI::AnsiEscapeCode.ansi.red
    #   Brut::TUI::AnsiEscapeCode.ansi.bold
    #   Brut::TUI::AnsiEscapeCode.ansi.underline
    #
    # @example Using RGB codes
    #   Brut::TUI::AnsiEscapeCode.ansi(87, 255, 128)
    #
    # @example Using code names
    #   Brut::TUI::AnsiEscapeCode.ansi(:bright_blue)
    #
    def ansi(*name)
      case name
      in [ r, g, b ]
        Brut::TUI::AnsiEscapeCode.new("rgb(#{r},#{g},#{b})", "38;2;#{r};#{g};#{b}")
      in []
        object
      else
        CODES.fetch(name[0].to_sym)
      end
    end
  end
  extend Mod
end
