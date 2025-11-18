# A string that responds to limited markup that can be used to apply styles to the string
class Brut::TUI::MarkupString
  # Create a MarkupString from a normal string.
  #
  # @param string [String|Brut::TUI::MarkupString] string to convert.
  # @return [Brut::TUI::MarkupString] if `string` is a `Brut::TUI::MarkupString` already, returns that, otherwise, wraps
  #         `string` in a `Brut::TUI::MarkupString`.
  def self.from_string(string)
    string.kind_of?(Brut::TUI::MarkupString) ? string : self.new(string.to_s)
  end

  def initialize(string)
    @string = string
  end

  DELIMITERS = {
    "*" => :bold,
    "_" => :weak,
    "`" => :code,
    "~" => :strike
  }.freeze

  # Parse the string for known markup, yielding at key parsing events.
  #
  # @yield [directive, value] called for each parsing event, where value depends on directive.  The block
  #        will be called for all parts of the string.
  # @yieldparam directive [Symbol] one of `:start`, `:stop`, or `:text`. `:text` is for any text and doesn't include
  #             the markup characters. `:start` and `:stop` are called when a markup start or stop is found.
  # @yieldparam value [String|Symbol] For the `:text` `directive`, this is the text fragment from the string, so
  #             for the string `"*foo*"`, `:text` would be called with `"foo"`.  For `:start` or `:stop`, the value
  #             is the type of markup encountered, one of `:bold`, `:weak`, `:code`, or `:strike`.
  def parse(&block)
    in_delimiter = DELIMITERS.keys.map { [ it, false ] }.to_h

    previous_character          = nil
    previous_previous_character = nil

    @string.each_char do |char|
      if DELIMITERS.key?(char) && previous_character != "\\" && previous_previous_character != "\\"
        style = DELIMITERS[char]
        if in_delimiter[char]
          block.(:stop, style)
          in_delimiter[char] = false
        else
          inside_code = in_delimiter["`"]
          if inside_code
            block.(:text, char)
          else
            block.(:start, style)
            in_delimiter[char] = true
          end
        end
      else
        if char == "\\"
          if previous_character == "\\"
            block.(:text, char)
          else
            # eat it - it is escaping something maybe
          end
        else
          block.(:text, char)
        end
      end
      previous_previous_character = previous_character
      previous_character          = char
    end
  end
end
