class FlashComponent < AppComponent
  def initialize(flash:)
    @flash = flash
  end

  CLASSES = [
    "f-1",
    "fw-bold",
    "w-50",
    "mv-3",
    "shadow-3",
    "pa-3",
    "ba",
    "br-3",
    "tc"
  ]
  COLORS = [
    "%{color}-300",
    "bg-%{color}-800",
    "bc-%{color}-700",
  ]

  def view_template
    if @flash.notice?
      div(role: "status",
          class: CLASSES + COLORS.map { it % { color: "blue" } }) do
        t(@flash.notice)
      end
    elsif @flash.alert?
      div(role: "alert",
          class: CLASSES + COLORS.map { it % { color: "orange" } }) do
        t(@flash.alert)
      end
    end
  end
end
