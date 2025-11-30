# A theme designed to work on a white background terminal.
class Brut::TUI::Themes::Light < Brut::TUI::TerminalTheme
  def black         = esc("38;2;0;0;0")
  def bright_black  = esc("38;2;64;64;64")
  def bright_white  = esc("38;2;128;128;128")
  def white         = esc("38;2;191;191;191")
  def yellow        = esc("38;2;191;191;0")
  def bright_yellow = esc("38;2;255;255;0")
  def normal        = super + black
  def code          = esc("38;2;0;128;0")
  def code_off      = normal
  def green         = esc("38;2;25;105;0")
  def bright_green  = esc("38;2;34;155;0")
  def bright        = bright_blue
  def bright_off    = normal
end

