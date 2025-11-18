module Brut
  # Brut provides a basic API for creating rich text user interfaces. Currently, Brut
  # provides {Brut::TUI::Script} to create more user-friendly scripts like `bin/setup` or
  # `bin/ci`.
  module TUI
    autoload(:EventLoop, "brut/tui/event_loop")
    autoload(:Events, "brut/tui/events")
    autoload(:AnsiEscapeCode, "brut/tui/ansi_escape_code")
    autoload(:Script, "brut/tui/script")
    autoload(:Terminal, "brut/tui/terminal")
    autoload(:TerminalTheme, "brut/tui/terminal_theme")
    autoload(:Themes, "brut/tui/themes")
    autoload(:MarkupString, "brut/tui/markup_string")
  end
end
