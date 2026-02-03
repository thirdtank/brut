require "lipgloss"
class Brut::CLI::TerminalTheme
  def initialize(terminal:)
    @terminal = terminal
  end

  def title
    @title ||= Lipgloss::Style.new.bold(true).foreground(white_strong)
  end
  def header
    @header ||= Lipgloss::Style.new.foreground(blue_strong)
  end
  def subheader
    @subheader ||= Lipgloss::Style.new.foreground(cyan_strong).italic(true)
  end
  def weak
    @weak ||= Lipgloss::Style.new.faint(true)
  end
  def url
    @url ||= Lipgloss::Style.new.underline(true).bold(true)
  end
  def code
    @code ||= Lipgloss::Style.new.foreground(cyan_strong).bold(true)
  end
  def bullet(n)
    @bullets ||= [
      Lipgloss::Style.new.foreground(yellow_strong).margin_right(1).margin_left(2),
      Lipgloss::Style.new.foreground(purple_strong).margin_right(1),
      Lipgloss::Style.new.foreground(yellow_weak).margin_right(1),
      Lipgloss::Style.new.foreground(purple_weak).margin_right(1),
    ]
    @bullets[n] || none
  end

  def none
    @none ||= Lipgloss::Style.new
  end

  def success
    @success ||= Lipgloss::Style.new.foreground(green_weak).bold(true)
  end

  def exception
    @exception ||= Lipgloss::Style.new.foreground(red_weak)
  end

  def error
    @error ||= Lipgloss::Style.new.foreground(red_strong).bold(true)
  end

  def warning
    @warning ||= Lipgloss::Style.new.foreground(yellow_strong).bold(true)
  end

  def wrap(text, indent:, max_width: nil)
    max_width ||= @terminal.cols
    text_width = [ max_width, @terminal.cols ].min
    lines = []
    text.split(/\s+/).each do |word|
      current_line = lines.last
      if current_line.nil?
        lines << []
        current_line = lines.last
      end
      if (current_line.join(" ").length + word.length + 1) > (text_width - indent)
        lines << [ word ]
      else
        current_line << word
      end
    end
    prefix = " " * indent
    lines.map { |line|
      prefix + line.join(" ")
    }.join("\n")
  end

private

  def black_weak
    @black_weak ||= Lipgloss::AdaptiveColor.new(light: "#6e6e6e", dark: "#3a3a3a")
  end
  def black_strong
    @black_strong ||= Lipgloss::AdaptiveColor.new(light: "#000000", dark: "#5a5a5a")
  end
  def red_weak
    @red_weak ||= Lipgloss::AdaptiveColor.new(light: "#a31515", dark: "#d16969")
  end
  def red_strong
    @red_strong ||= Lipgloss::AdaptiveColor.new(light: "#d40000", dark: "#f44747")
  end
  def green_weak
    @green_weak ||= Lipgloss::AdaptiveColor.new(light: "#2b6a2b", dark: "#6a9955")
  end
  def green_strong
    @green_strong ||= Lipgloss::AdaptiveColor.new(light: "#007f00", dark: "#89d185")
  end
  def yellow_weak
    @yellow_weak ||= Lipgloss::AdaptiveColor.new(light: "#8a6d1d", dark: "#d7ba7d")
  end
  def yellow_strong
    @yellow_strong ||= Lipgloss::AdaptiveColor.new(light: "#b58900", dark: "#ffcc66")
  end
  def blue_weak
    @blue_weak ||= Lipgloss::AdaptiveColor.new(light: "#005f87", dark: "#569cd6")
  end
  def blue_strong
    @blue_strong ||= Lipgloss::AdaptiveColor.new(light: "#0047ab", dark: "#4fc1ff")
  end
  def purple_weak
    @purple_weak ||= Lipgloss::AdaptiveColor.new(light: "#6f42c1", dark: "#c586c0")
  end
  def purple_strong
    @purple_strong ||= Lipgloss::AdaptiveColor.new(light: "#5a2ca0", dark: "#d670d6")
  end
  def cyan_weak
    @cyan_weak ||= Lipgloss::AdaptiveColor.new(light: "#006f6f", dark: "#4ec9b0")
  end
  def cyan_strong
    @cyan_strong ||= Lipgloss::AdaptiveColor.new(light: "#007acc", dark: "#2dd4bf")
  end
  def white_weak
    @white_weak ||= Lipgloss::AdaptiveColor.new(light: "#ffffff", dark: "#cfcfcf")
  end
  def white_strong
    @white_strong ||= Lipgloss::AdaptiveColor.new(light: "#f0f0f0", dark: "#ffffff")
  end
end
