require "spec_helper"
require "pathname"

# Verifies that Brut::FrontEnd::Component exposes a Phlex element method for
# every custom element BLOK's JS registers.
#
# BLOK's source of truth is expected at `../blok` (sibling checkout). Set
# `BLOK_SRC` to point elsewhere. If the source is not present, these examples
# are skipped rather than failed.
#
# Tag names are read from `static tagName = "..."` in
# `../blok/src/js/custom-elements/*.js`, which is the value each element passes
# to `customElements.define` via `BaseCustomElement.define`.
RSpec.describe Brut::FrontEnd::Component, "BLOK custom element registration" do
  let(:blok_src) do
    Pathname(ENV.fetch("BLOK_SRC") { File.expand_path("../../../../blok", __dir__) })
  end
  let(:custom_elements_dir) { blok_src / "src/js/custom-elements" }
  let(:registered_elements) { Brut::FrontEnd::Component.__registered_elements__ }

  let(:blok_tag_names) do
    custom_elements_dir.glob("*.js").flat_map { |file|
      file.read.scan(/^\s*static tagName = ["']([^"']+)["']/).flatten
    }.uniq.sort
  end

  before do
    skip "BLOK source not found at #{custom_elements_dir} (set BLOK_SRC)" unless custom_elements_dir.directory?
  end

  it "reads BLOK's custom element tag names" do
    expect(blok_tag_names).to_not be_empty
  end

  it "registers every BLOK custom element" do
    missing = blok_tag_names.reject { |tag_name| registered_elements.value?(tag_name) }

    expect(missing).to eq([]), <<~MESSAGE
      BLOK custom elements not registered in Brut::FrontEnd::Component.
      Add these to lib/brut/front_end/component.rb:

      #{missing.map { |tag_name| "  register_element :#{tag_name.tr("-", "_")}" }.join("\n")}
    MESSAGE
  end

  it "registers each BLOK custom element as its conventional element method" do
    problems = blok_tag_names.filter_map { |tag_name|
      expected_method = tag_name.tr("-", "_").to_sym
      next if registered_elements[expected_method] == tag_name

      if registered_elements.key?(expected_method)
        "  #{expected_method} is registered as <#{registered_elements[expected_method]}> instead of <#{tag_name}>"
      elsif registered_elements.value?(tag_name)
        other_method = registered_elements.key(tag_name)
        "  <#{tag_name}> is registered as #{other_method} instead of #{expected_method}"
      end
    }

    expect(problems).to eq([]), <<~MESSAGE
      These BLOK custom elements are not available under their conventional element method:
      #{problems.join("\n")}
    MESSAGE
  end

  it "does not register blok-* elements that BLOK does not define" do
    stale = registered_elements.select { |method_name, _| method_name.to_s.start_with?("blok_") }
                             .reject { |_, tag_name| blok_tag_names.include?(tag_name) }

    expect(stale).to eq({}), <<~MESSAGE
      Brut::FrontEnd::Component registers blok-* elements that BLOK does not define:
      #{stale.map { |method_name, tag_name| "  #{method_name} (<#{tag_name}>)" }.join("\n")}
    MESSAGE
  end
end
