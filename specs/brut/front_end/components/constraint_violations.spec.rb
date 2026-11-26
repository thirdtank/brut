require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::ConstraintViolations do
  let(:translations) do
    {
      cv: {
        this_field: "This field",
        cs: {
          valueMissing: "%{field} is required",
          tooShort: "%{field} is too short",
          patternMismatch: "%{field} is invalid",
        },
        ss: {
          taken: "%{field} is already taken",
          too_short: "%{field} must be at least %{minlength} characters",
        },
      },
    }
  end

  around do |example|
    original_backend   = I18n.backend
    original_load_path = I18n.load_path
    original_available = I18n.available_locales_initialized? ? I18n.available_locales : nil

    I18n.load_path = []
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, translations)
    I18n.available_locales = [:en]
    I18n.locale = :en

    example.run
  ensure
    I18n.available_locales = original_available
    I18n.load_path = original_load_path
    I18n.backend = original_backend
  end

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)
  end

  let(:form_class) {
    Class.new(Brut::FrontEnd::Form) do
      input :name
    end
  }

  def render(**options)
    Nokogiri::HTML5.fragment(described_class.new(**options).call)
  end

  it "renders a blok-cv-messages element that wraps the input's messages" do
    document = render(form: form_class.new, input_name: :name)

    expect(document.at_css("blok-cv-messages")).not_to eq(nil)
    expect(document.at_css("blok-cv-messages")["input-name"]).to eq("name")
  end

  it "does not render client-side messages for a new form" do
    document = render(form: form_class.new, input_name: :name)

    expect(document.at_css("blok-cv-messages")).not_to eq(nil)
    expect(document.css("blok-cv")).to be_empty
  end

  it "renders a server-generated client-side message for an invalid, non-new form" do
    form = form_class.new(params: { name: "" })

    document = render(form:, input_name: :name)
    messages = document.css("blok-cv")

    expect(messages.length).to eq(1)
    expect(messages.first.key?("server-generated")).to eq(true)
    expect(messages.first.key?("client-side")).to eq(true)
    expect(messages.first.text).to eq("This field is required")
  end

  it "renders a server-generated server-side message even for a new form" do
    form = form_class.new
    form.server_side_constraint_violation(input_name: :name, key: :taken)

    document = render(form:, input_name: :name)
    messages = document.css("blok-cv")

    expect(messages.length).to eq(1)
    expect(messages.first.key?("server-generated")).to eq(true)
    expect(messages.first.key?("server-side")).to eq(true)
    expect(messages.first.text).to eq("This field is already taken")
  end

  it "renders both client-side and server-side messages for a non-new form" do
    form = form_class.new(params: { name: "" })
    form.server_side_constraint_violation(input_name: :name, key: :taken)

    document = render(form:, input_name: :name)
    messages = document.css("blok-cv")

    expect(messages.map(&:text)).to eq([
      "This field is required",
      "This field is already taken",
    ])
    expect(messages.map { |message| message.key?("client-side") }).to eq([true, false])
    expect(messages.map { |message| message.key?("server-side") }).to eq([false, true])
  end

  it "renders one message for each client-side constraint violation" do
    form_class = Class.new(Brut::FrontEnd::Form) do
      input :code, minlength: 5, pattern: "^[0-9]+$"
    end
    form = form_class.new(params: { code: "abc" })

    document = render(form:, input_name: :code)

    expect(document.css("blok-cv").map(&:text)).to eq([
      "This field is too short",
      "This field is invalid",
    ])
  end

  it "uses input-name with [] for an array input" do
    form_class = Class.new(Brut::FrontEnd::Form) do
      input :items, array: true
    end
    form = form_class.new(params: { items: ["", "ok"] })

    document = render(form:, input_name: :items, index: 0)

    expect(document.at_css("blok-cv-messages")["input-name"]).to eq("items[]")
    expect(document.css("blok-cv").map(&:text)).to eq(["This field is required"])
  end

  it "uses the selected array index's constraint violations" do
    form_class = Class.new(Brut::FrontEnd::Form) do
      input :items, array: true
    end
    form = form_class.new(params: { items: ["", "ok"] })

    first = render(form:, input_name: :items, index: 0)
    second = render(form:, input_name: :items, index: 1)

    expect(first.css("blok-cv").map(&:text)).to eq(["This field is required"])
    expect(second.css("blok-cv")).to be_empty
  end

  it "passes through attributes for the blok-cv-messages element" do
    document = render(
      form: form_class.new,
      input_name: :name,
      id: "name-errors",
      class: "errors",
    )
    messages = document.at_css("blok-cv-messages")

    expect(messages).not_to eq(nil)
    expect(messages["id"]).to eq("name-errors")
    expect(messages["class"]).to eq("errors")
  end

  it "passes through attributes for each blok-cv element" do
    form = form_class.new(params: { name: "" })

    document = render(
      form:,
      input_name: :name,
      message_html_attributes: {
        class: "constraint",
        "data-testid": "name-constraint",
      },
    )
    messages = document.at_css("blok-cv")

    expect(messages).not_to eq(nil)
    expect(messages["class"]).to eq("constraint")
    expect(messages["data-testid"]).to eq("name-constraint")
  end

  it "interpolates server-side context into the message" do
    form = form_class.new(params: { name: "Dave" })
    form.server_side_constraint_violation(
      input_name: :name,
      key: :too_short,
      context: { minlength: 5 },
    )

    document = render(form:, input_name: :name)
    message = document.at_css("blok-cv")

    expect(message).not_to eq(nil)
    expect(message.text).to eq("This field must be at least 5 characters")
  end

  it "renders an empty messages container for a valid, non-new form" do
    form = form_class.new(params: { name: "Dave" })

    document = render(form:, input_name: :name)

    expect(document.at_css("blok-cv-messages")).not_to eq(nil)
    expect(document.css("blok-cv")).to be_empty
  end
end
