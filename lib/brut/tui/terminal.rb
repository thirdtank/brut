require "io/console"
require "timeout"
require "stringio"

# Stores metdata about the current temrinal in use. This should provide any metadata
# about the terminal that can be reliably determined. 
class Brut::TUI::Terminal

  def initialize
    trap("WINCH") do
      @winsize = IO.console.winsize
    end
  end

  # Number of rows for the current terminal. Should be consistent even after a resize
  def rows = winsize[0]
  # Number of columns for the current terminal. Should be consistent even after a resize
  def cols = winsize[1]

  # The IO used for outputing information to the terminal. Prefer this over `STDOUT`.
  def io    = $stdout

  # The IO to use for requesting input from the user
  def stdin = $stdin
  
  # Best attempt to guess the background color of the current terminal.
  # This will not refresh if that color is changed, and its behavior will
  # default to black if determining the color doesn't work or isn't supported.
  def background_color
    @bakground_color ||= begin
                           io.write "\e]11;?\a"
                           io.flush

                           result = nil

                           begin
                             # Read the reply, which should look like:
                             #   ESC ] 11 ; rgb:0000/0000/0000 BEL
                             Timeout.timeout(0.1) do
                               buf = +""
                               loop do
                                 ch = stdin.getch
                                 buf << ch
                                 break if ch == "\a" || buf.end_with?("\e\\") # BEL or ST terminator
                               end
                               result = buf
                             end
                           rescue Timeout::Error
                             # no reply within 100ms — terminal probably doesn’t support it
                           end

                           rgb = [ 0, 0, 0 ]
                           if result
                             if result =~ /\e\]11;([^ \a\e]*)[\a\e\\]/
                               color = Regexp.last_match(1)
                               parts = color[/rgb:(.*)/, 1]&.split("/")
                               if parts

                                 rgb = parts.map { it.to_i(16) / 0xffff.to_f * 256 }.map(&:to_i)
                               end
                             end
                           end
                           rgb
                         end
  end


private

  def winsize
    @winsize ||= IO.console.winsize
  end

end
