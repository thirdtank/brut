# A theme without any ANSI styling at all.  This is suitable
# for showing to a user who does not want any colors or styles, but
# still wants to see output in a somewhat conventional way.
class Brut::TUI::Themes::None < Brut::TUI::TerminalTheme
  def esc(*) = ""
end



