# A theme designed to work on a dark background terminal.
class Brut::TUI::Themes::Dark < Brut::TUI::TerminalTheme
  def black         = esc("38;2;96;96;96")
  def bright_black  = esc("38;2;128;128;128")
  def white         = esc("38;2;233;233;233")
  def bright_white  = esc("38;2;255;255;255")
  def yellow        = esc("38;2;191;191;0")
  def bright_yellow = esc("38;2;255;255;0")
  def normal        = super + white
  def code          = esc("38;2;0;255;0")
  def code_off      = normal
  def bright        = bright_white
  def bright_off    = normal
end
