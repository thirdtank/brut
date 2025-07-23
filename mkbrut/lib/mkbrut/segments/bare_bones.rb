# The bare bones configuration on top of a blank Brut app.
class MKBrut::Segments::BareBones < MKBrut::Base

  def self.friendly_name = "Bare bones framing"

  def initialize(app_options:, current_dir:, templates_dir:)
    @project_root  = current_dir / app_options.app_name
    @templates_dir = templates_dir / "segments" / "BareBones"
    @erb_binding   = ErbBindingDelegate.new(app_options)
  end

  def add!

    operations = copy_files(@templates_dir, @project_root) + 
                 other_operations(@project_root)

    operations.each do |operation|
      operation.call
    end

  end

  def other_operations(project_root)
    [
      MKBrut::Ops::InsertRoute.new(
        project_root: @project_root,
        code: %{path "/trigger_exception", method: :get}
      ),
      MKBrut::Ops::InsertCodeInMethod.new(
        file: @project_root / "app" / "src" / "app.rb",
        class_name: "App",
        method_name: "initialize",
        code: %{
Brut.container.store(
  "trigger_exception_key",
  String,
  "String used to prevent anyone from triggering exceptions in TriggerExceptionHandler"
) do
  ENV.fetch("TRIGGER_EXCEPTION_KEY")
end},
      ),
      InsertCustomElement.new(
        project_root: @project_root,
        element_class_name: "Example",
      ),
      MKBrut::Ops::InsertCodeInMethod.new(
        file: @project_root / "app" / "src" / "front_end" / "pages" / "home_page.rb",
        class_name: "HomePage",
        method_name: "page_template",
        code: %{
#{ @erb_binding.prefix }_example(
  transform: "upper",
  class: [ "pos-fixed",
           "bottom-0",
           "left-0",
           "w-100",
           "ff-sans",
           "lh-title",
           "tracked",
           "f-5",
           "f-6-ns",
           "tc",
           "pa-3",
           "mt-3",
           "db", ]
) do
  "We Like the Web"
end
}
      ),
      InsertEndToEndTestCode.new(
        file: @project_root / "specs" / "e2e" / "home_page.spec.rb",
        code: %{
    example = page.locator("#{ @erb_binding.prefix }-example")
    # The #{ @erb_binding.prefix }-example custom element will transform
    # the text it contains.  Since this is an end-to-end test
    # the element should've done its thing and given us 
    # upper-case text.
    expect(example).to have_text("WE LIKE THE WEB") }
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / ".env.development",
        content: %{
# Key used to allow triggering an exception. This is required to prevent
# just anyone from triggering one.
TRIGGER_EXCEPTION_KEY=dev-trigger-exception
}
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / ".env.test",
        content: "TRIGGER_EXCEPTION_KEY=test-trigger-exception"
      ),

    ]
  end
  class InsertCustomElement < MKBrut::Ops::BaseOp
    def initialize(project_root:, element_class_name:)
      @file               = project_root / "app" / "src" / "front_end" / "js" / "index.js"
      @element_class_name = element_class_name
    end
    def call
      if dry_run?
        puts "Would insert custom element '#{@element_class_name}' into #{@file}"
        return
      end
      inserted = false
      new_source = []
      File.read(@file).split("\n").each do  |line|
        regexp = /^document\.addEventListener\(\"DOMContentLoaded\"/
        if line.match?(regexp)
          new_source << %{import #{@element_class_name} from "./#{@element_class_name}"}
          new_source << line
          new_source << %{  #{@element_class_name}.define()}
          inserted = true
        else
          new_source << line
        end
      end
      if !inserted
        raise "Could not find a place to insert code in '#{@file}'. Trying to find a line that matches this regular expression:\n\n#{regexp.inspect}"
      end
      File.open(@file, "w") do |file|
        file.puts new_source.join("\n")
      end
    end
  end

  class InsertEndToEndTestCode < MKBrut::Ops::PrismParsingOp
    def initialize(file:, code:)
      @file = file
      @code = code
    end
    def call
      if dry_run?
        puts "Would insert end-to-end test code into #{@file}:\n\n#{@code}\n"
        return
      end
      parse_file!

      found_describe = false
      first_it_block = nil

      @tree.value.statements.body.each do |top|
        if top.is_a?(Prism::CallNode) &&
           top.name == :describe      &&
           top.block
          found_describe = true

          statements = top.block.body
          if statements.respond_to?(:body)
            statements.body.each do |statement|
              if statement.is_a?(Prism::CallNode) &&
                 statement.name == :it            &&
                 statement.block

                first_it_block = statement
                break

              end
            end
          end
        end
      end
      if !first_it_block
        if found_describe
        raise "Could not find an 'it' block inside the first 'describe' in '#{@file}'"
        else
        raise "Could not find a 'describe' block in '#{@file}'"
        end
      end

      insertion_point = first_it_block.block.location.end_offset - 3

      block_line = @source.lines[first_it_block.location.start_line - 1]
      describe_indent = block_line[/^\s*/] 
      it_indent = describe_indent + "  "

      new_source = @source.dup.insert(insertion_point, "\n#{it_indent}#{@code}\n#{describe_indent}")
      File.open(@file, "w") do |file|
        file.puts new_source
      end
    end
  end

end
