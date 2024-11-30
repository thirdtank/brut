require "brut/cli"

class Brut::CLI::Apps::Scaffold < Brut::CLI::App
  description "Create scaffolds of various files to help develop more quckly"
  opts.on("--overwrite", "If set, any files that exists already will be overwritten by new scaffolds")
  opts.on("--dry-run", "If set, no files are changed. You will see output of what would happen without this flag")

  def before_execute
    ENV["RACK_ENV"] = "development"
  end

  class Test < Brut::CLI::Command
    description "Create the shell of a unit test based on an existing source file"
    args "source_file_paths..."
    def execute
      if args.empty?
        err.puts "'test' requires one or more files to scaffold a test for"
        return 1
      end
      files_to_test_files = args.map { |arg|
        Pathname(arg).expand_path
      }.map { |pathname|
        relative = pathname.relative_path_from(Brut.container.app_src_dir)
        test_file = Brut.container.app_specs_dir / relative.dirname / "#{relative.basename(relative.extname)}.spec.rb"
        [ pathname, test_file ]
      }.to_h

      non_existent_sources  = files_to_test_files.keys.select   { |pathname| !pathname.exist? }
      existent_destinations = files_to_test_files.values.select { |pathname| pathname.exist? }

      if non_existent_sources.any?
        relative_paths = non_existent_sources.map { |pathname| pathname.relative_path_from(Brut.container.project_root) }
        err.puts "Not all input files exist:"
        relative_paths.each do |file|
          err.puts file
        end
        return 1
      end

      if existent_destinations.any? && !global_options.overwrite?
        relative_paths = existent_destinations.map { |pathname| pathname.relative_path_from(Brut.container.project_root) }
        err.puts "Some files to be generated already exist. Set --overwrite to overwrite them:"
        relative_paths.each do |file|
          err.puts file
        end
        return 1
      end

      files_to_test_files.each do |source,destination|
        result = Prism.parse_file(source.to_s)
        if !result
          raise "For some reason Prism did not parse #{source.to_s}"
        end
        classes = find_classes(result.value).map { |(module_nodes,class_node)|
          (module_nodes.map(&:constant_path).map(&:full_name).map(&:to_s) + [class_node.constant_path.full_name.to_s]).compact.join("::")
        }


        out.puts "#{destination} will contain tests for:\n#{classes.join("\n")}\n\n"

        code = ["require \"spec_helper\"\n"] + classes.map { |class_name|
          %{RSpec.describe #{class_name} do
  it "should have tests" do
    expect(false).to eq(true)
  end
end}
        }

        if global_options.dry_run?
          puts code
        else
          FileUtils.mkdir_p destination.dirname
          File.open(destination,"w") do |file|
            file.puts code
          end
        end
      end

      0
    end

  private

    def find_classes(ast,current_modules = [])
      classes = []
      if ast.nil?
        return classes
      end
      new_module = nil
      if ast.kind_of?(Prism::ClassNode)
        classes << [ current_modules, ast ]
        new_module = ast
      elsif ast.kind_of?(Prism::ModuleNode)
        new_module = ast
      end
      ast.child_nodes.each do |child|
        new_current_modules = current_modules + [ new_module ]
        result = find_classes(child, new_current_modules.compact)
        classes = classes + result
      end
      classes
    end
  end

  class E2ETest < Brut::CLI::Command
    description "Create the shell of an end-to-end test"
    args "test_name"
    def self.command_name = "test:e2e"

    opts.on("--path PATH","Path within the e2e tests to create the file")
    def execute
      if args.empty?
        err.puts "'#{self.class.command_name}' requires a name"
        return 1
      end
      test_name = args.join(" ").gsub(/\"/,"'")
      test_file_name = args.join("_").gsub(/\W/,"_").gsub(/__+/,"_").downcase + ".spec.rb"
      test_file_dir = Brut.container.e2e_specs_dir
      if !options.path.nil?
        test_file_dir = test_file_dir / options.path
      end

      path_to_test_file = test_file_dir / test_file_name

      verb         = "Created"
      dry_run_verb = "create"

      if path_to_test_file.exist?
        if global_options.overwrite?
          verb         = "Overwrote"
          dry_run_verb = "overwrite"
        else
          err.puts "#{path_to_test_file.relative_path_from(Brut.container.project_root)} exists. Use --overwrite to replace it"
          return 1
        end
      end


        code = %{require "spec_helper"

RSpec.describe "#{test_name}" do
  it "should have tests" do
    page.goto("/")
    expect(page).to be_page_for(page_class_here)
  end
end}
      if global_options.dry_run?
        out.puts "Will #{dry_run_verb} #{path_to_test_file.relative_path_from(Brut.container.project_root)} with this code:"
        out.puts_no_prefix
        out.puts_no_prefix code
      else
        FileUtils.mkdir_p test_file_dir
        File.open(path_to_test_file,"w") do |file|
          file.puts code
        end
        out.puts "#{verb} #{path_to_test_file.relative_path_from(Brut.container.project_root)}"
      end
      0
    end

  private

    def find_classes(ast,current_modules = [])
      classes = []
      if ast.nil?
        return classes
      end
      new_module = nil
      if ast.kind_of?(Prism::ClassNode)
        classes << [ current_modules, ast ]
        new_module = ast
      elsif ast.kind_of?(Prism::ModuleNode)
        new_module = ast
      end
      ast.child_nodes.each do |child|
        new_current_modules = current_modules + [ new_module ]
        result = find_classes(child, new_current_modules.compact)
        classes = classes + result
      end
      classes
    end
  end

  class Component < Brut::CLI::Command
    description "Create a new component, template, and associated test"
    opts.on("--page","If set, this component is for a specific page and won't go with the other components")
    args "ComponentName"
    def execute
      if args.length != 1
        raise "component requires exactly one argument, got #{args.length}"
      end
      class_name = RichString.new(args[0])
      if class_name.to_s !~ /Component$/
        class_name = RichString.new(class_name.to_s + "Component")
      end

      relative_path = class_name.underscorized

      components_src_dir   = Brut.container.components_src_dir
      components_specs_dir = Brut.container.components_specs_dir

      if options.page?
        components_src_dir   = Brut.container.pages_src_dir
        components_specs_dir = Brut.container.pages_specs_dir
        if class_name.to_s !~ /::/
          raise "component #{class_name} cannot be a page component - it must be an inner class of an existing page"
        else
          existing_page = RichString.new(class_name.to_s.split(/::/)[0..-2].join("::")).underscorized.to_s + ".rb"

          if !(components_src_dir / existing_page).exist?
            raise "#{class_name} was set as a page component, however we cannot find the page it belongs in.  File #{existing_page} does not exist and should contain that page"
          end
        end
      end

      source_path      = Pathname( (components_src_dir / relative_path).to_s + ".rb" )
      html_source_path = Pathname( (components_src_dir / relative_path).to_s + ".html.erb" )
      spec_path        = Pathname( (components_specs_dir / relative_path).to_s + ".spec.rb" )

      exists = [
        source_path,
        html_source_path,
        spec_path,
      ].select(&:exist?)

      if exists.any? && !global_options.overwrite?
        exists.each do |path|
          err.puts "'#{path.relative_path_from(Brut.container.project_root)}' exists already"
        end
        err.puts "Re-run with --overwrite to overwrite these files"
        return 1
      end

      if global_options.dry_run?
        puts "FileUtils.mkdir_p #{source_path.dirname}"
        puts "FileUtils.mkdir_p #{html_source_path.dirname}"
        puts "FileUtils.mkdir_p #{spec_path.dirname}"
      else
        FileUtils.mkdir_p source_path.dirname
        FileUtils.mkdir_p html_source_path.dirname
        FileUtils.mkdir_p spec_path.dirname

        File.open(source_path,"w") do |file|
          file.puts %{class #{class_name} < AppComponent
  def initialize
  end
end}
        end
        File.open(html_source_path,"w") do |file|
          file.puts "<h1>#{class_name} is ready!</h1>"
        end
        File.open(spec_path,"w") do |file|
          file.puts %{require "spec_helper"

RSpec.describe #{class_name} do
  it "should have tests" do
    expect(true).to eq(false)
  end
end}
        end
      end
      out.puts "Component source is in        #{source_path.relative_path_from(Brut.container.project_root)}"
      out.puts "Component HTML template is in #{html_source_path.relative_path_from(Brut.container.project_root)}"
      out.puts "Component test is in          #{spec_path.relative_path_from(Brut.container.project_root)}"
      0
    end
  end
  class Page < Brut::CLI::Command
    description "Create a new page, template, and associated test"
    args "PageName"
    def execute
      if args.length != 1
        raise "page requires exactly one argument, got #{args.length}"
      end
      class_name = RichString.new(args[0])
      if class_name.to_s !~ /Page$/
        class_name = RichString.new(class_name.to_s + "Page")
      end

      relative_path = class_name.underscorized

      pages_src_dir    = Brut.container.pages_src_dir
      pages_specs_dir  = Brut.container.pages_specs_dir
      i18n_locales_dir = Brut.container.i18n_locales_dir

      source_path      = Pathname( (pages_src_dir / relative_path).to_s + ".rb" )
      html_source_path = Pathname( (pages_src_dir / relative_path).to_s + ".html.erb" )
      spec_path        = Pathname( (pages_specs_dir / relative_path).to_s + ".spec.rb" )
      app_translations = Pathname(  i18n_locales_dir / "en" / "2_app.rb")

      exists = [
        source_path,
        html_source_path,
        spec_path,
      ].select(&:exist?)

      if exists.any? && !global_options.overwrite?
        exists.each do |path|
          err.puts "'#{path.relative_path_from(Brut.container.project_root)}' exists already"
        end
        err.puts "Re-run with --overwrite to overwrite these files"
        return 1
      end

      if global_options.dry_run?
        puts "FileUtils.mkdir_p #{source_path.dirname}"
        puts "FileUtils.mkdir_p #{html_source_path.dirname}"
        puts "FileUtils.mkdir_p #{spec_path.dirname}"
        puts "Would add a title to #{app_translations}"
      else
        FileUtils.mkdir_p source_path.dirname
        FileUtils.mkdir_p html_source_path.dirname
        FileUtils.mkdir_p spec_path.dirname

        File.open(source_path,"w") do |file|
          file.puts %{class #{class_name} < AppPage
  def initialize
  end
end}
        end
        File.open(html_source_path,"w") do |file|
          file.puts "<h1>#{class_name} is ready!</h1>"
        end
        File.open(spec_path,"w") do |file|
          file.puts %{require "spec_helper"

RSpec.describe #{class_name} do
  it "should have tests" do
    expect(true).to eq(false)
  end
end}
        end
        title = RichString.new(class_name).underscorized.humanized.to_s.capitalize
        existing_translations = File.read(app_translations).split(/\n/)
        inserted_translation = false
        File.open(app_translations,"w") do |file|
          existing_translations.each do |line|
            if line =~ /^    pages:\s*{/
              file.puts line
              file.puts "      \"#{class_name}\": {\n"
              file.puts "        title: \"#{title}\","
              file.puts "      },"
              inserted_translation = true
            else
            file.puts line
            end
          end
        end
        if !inserted_translation
          err.puts "WARNING: Could not find a place to insert the translation for this page's title"
          err.puts "         The page may not render properly the first time you load it"
        end
      end
      out.puts "Page source is in        #{source_path.relative_path_from(Brut.container.project_root)}"
      out.puts "Page HTML template is in #{html_source_path.relative_path_from(Brut.container.project_root)}"
      out.puts "Page test is in          #{spec_path.relative_path_from(Brut.container.project_root)}"
      0
    end
  end
  class Form < Brut::CLI::Command
    description "Create a new form and handler"
    args "FormName"
    def execute
      if args.length != 1
        raise "form requires exactly one argument, got #{args.length}"
      end
      normalized_arg = args[0].gsub(/Form$/,"").gsub(/Handler$/,"")

      class_name         = RichString.new(normalized_arg + "Form")
      handler_class_name = RichString.new(normalized_arg + "Handler")

      relative_path         = class_name.underscorized
      handler_relative_path = handler_class_name.underscorized

      forms_src_dir      = Brut.container.forms_src_dir
      handlers_src_dir   = Brut.container.handlers_src_dir
      handlers_specs_dir = Brut.container.handlers_specs_dir

      source_path         = Pathname( (forms_src_dir      / relative_path).to_s + ".rb" )
      handler_source_path = Pathname( (handlers_src_dir   / handler_relative_path).to_s + ".rb" )
      handler_spec_path   = Pathname( (handlers_specs_dir / handler_relative_path).to_s + ".spec.rb" )

      exists = [
        source_path,
        handler_source_path,
        handler_spec_path,
      ].select(&:exist?)

      if exists.any? && !global_options.overwrite?
        exists.each do |path|
          err.puts "'#{path.relative_path_from(Brut.container.project_root)}' exists already"
        end
        err.puts "Re-run with --overwrite to overwrite these files"
        return 1
      end

      if global_options.dry_run?
        out.puts "Ensure directories exist for source code:\n\n"
        out.puts "  #{source_path.dirname}"
        out.puts "  #{handler_source_path.dirname}"
        out.puts "  #{handler_spec_path.dirname}"
      else
        FileUtils.mkdir_p source_path.dirname
        FileUtils.mkdir_p handler_source_path.dirname
        FileUtils.mkdir_p handler_spec_path.dirname

        File.open(source_path,"w") do |file|
          file.puts %{class #{class_name} < AppForm
  input :some_field, minlength: 3
end}
        end
        File.open(handler_source_path,"w") do |file|
          file.puts %{class #{handler_class_name} < AppHandler
  def handle(form:) # add other args here as needed
    raise "You need to implement your Handler\#{form.class.input_definitions.length < 2 ? " and likely your Form as well" : ""}"
  end
end}
        end
        File.open(handler_spec_path,"w") do |file|
          file.puts %{require "spec_helper"

RSpec.describe #{handler_class_name} do
  subject(:handler) { described_class.new }
  describe "#handle!" do
    it "needs tests" do
      expect(true).to eq(false)
    end
  end
end}
        end
      end
      ## TODO: Extract or copy this to the other generators
      class_name_length = [ class_name.length, handler_class_name.length, "Spec".length ].max
      printf_string = if global_options.dry_run?
                        "%-#{class_name_length}s would be created in %s\n"
                      else
                        "%-#{class_name_length}s in %s\n"
                      end
      out.puts "\n\n"
      out.printf printf_string,class_name,source_path.relative_path_from(Brut.container.project_root)
      out.printf printf_string,handler_class_name, handler_source_path.relative_path_from(Brut.container.project_root)
      out.printf printf_string,"Spec", handler_spec_path.relative_path_from(Brut.container.project_root)
      0
    end
  end
  class CustomElementTest < Brut::CLI::Command
    description "Create a test for a custom element in your app"
    args "path_to_js_files..."
    def execute
      if args.empty?
        err.puts "'custom-element-test' requires one or more files to scaffold a test for"
        return 1
      end

      if args.any? { |file| Pathname(file).extname != ".js" }
        err.puts "'custom-element-test' must be given only .js files"
        return 1
      end

      files_to_create = args.map { |arg|
        path = Pathname(arg).expand_path
        relative_path = path.relative_path_from(Brut.container.js_src_dir)
        relative_path_as_spec = relative_path.dirname / (relative_path.basename(relative_path.extname).to_s + ".spec.js")
        spec_path = Brut.container.js_specs_dir / relative_path_as_spec
        [ path, spec_path ]
      }

      existing_files = files_to_create.select { |_,spec|
        spec.exist?
      }

      if existing_files.any? && !global_options.overwrite?
        relative_paths = existing_files.map { |_,pathname| pathname.relative_path_from(Brut.container.project_root) }
        err.puts "Some files to be generated already exist. Set --overwrite to overwrite them:"
        relative_paths.each do |file|
          err.puts file
        end
        return 1
      end

      files_to_create.each do |source_file, spec_file|
        source_class = source_file.basename(source_file.extname)
        tag_name = File.read(source_file).split(/\n/).map { |line|
          if line =~ /static\s+tagName\s*=\s*\"([^"]+)\"/
            "<#{$1}>"
          else
            nil
          end
        }.compact.first
        description = tag_name || source_class
        code =  %{import { withHTML } from "brut-js/testing/index.js"

describe("#{description}", () => {
  withHTML(`
  #{ tag_name ? "#{tag_name}" : "<!-- HTML here -->" }
  #{ tag_name ? "#{tag_name.gsub(/^</,'</')}" : "" }
  `).test("description here", ({document,window,assert}) => {
    assert.fail("test goes here")
  })
})}
        if global_options.dry_run?
          out.puts "Would generate this code:\n\n#{code}"
        else
          File.open(spec_file, "w") do |file|
            file.puts code
          end
        end
      end

      0
    end
  end
end
