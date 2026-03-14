require "prism"
require "brut/cli"

class Brut::CLI::Apps::Scaffold < Brut::CLI::Commands::BaseCommand
  def description = "Create scaffolds of various files to help develop more quckly"

  def commands
    super - [ Brut::CLI::Apps::Scaffold::BaseCommand ]
  end

  class BaseCommand < Brut::CLI::Commands::BaseCommand
    def bootstrap? = false
    def default_rack_env = "development"
    def opts = [
      [ "--overwrite", "If set, any files that exists already will be overwritten by new scaffolds" ],
      [ "--dry-run", "If set, no files are changed. You will see output of what would happen without this flag"],
    ]
  end

  class Test < BaseCommand
    def description = "Create the shell of a unit test based on an existing source file"
    def args_description = "source_file_paths..."
    def run
      if argv.empty?
        error "'test' requires one or more files to scaffold a test for"
        return 1
      end
      files_to_test_files = argv.map { |arg|
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
        error "Not all input files exist:"
        relative_paths.each do |file|
          error file
        end
        return 1
      end

      if existent_destinations.any? && !options.overwrite?
        relative_paths = existent_destinations.map { |pathname| pathname.relative_path_from(Brut.container.project_root) }
        error "Some files to be generated already exist. Set --overwrite to overwrite them:"
        relative_paths.each do |file|
          error file
        end
        return 1
      end

      files_to_test_files.each do |source,destination|
        result = Prism.parse_file(source.to_s)
        if !result
          raise "For some reason Prism did not parse #{source}"
        end
        classes = find_classes(result.value).map { |(module_nodes,class_node)|
          (module_nodes.map(&:constant_path).map(&:full_name).map(&:to_s) + [class_node.constant_path.full_name.to_s]).compact.join("::")
        }


        puts "#{destination} will contain tests for:\n#{classes.join("\n")}\n\n"

        code = ["require \"spec_helper\"\n"] + classes.map { |class_name|
          %{RSpec.describe #{class_name} do
  it "should have tests" do
    expect(false).to eq(true)
  end
end}
        }

        if options.dry_run?
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

  class E2ETest < BaseCommand
    def description = "Create the shell of an end-to-end test"
    def args_description = "test_name"
    def name = "e2e_test"

    def opts = super + [
      ["--path PATH","Path within the e2e tests to create the file"],
    ]

    def run
      if argv.empty?
        error "'#{self.class.command_name}' requires a name"
        return 1
      end
      test_name = argv.join(" ").gsub(/\"/,"'")
      test_file_name = argv.join("_").gsub(/\W/,"_").gsub(/__+/,"_").downcase + ".spec.rb"
      test_file_dir = Brut.container.e2e_specs_dir
      if !options.path.nil?
        test_file_dir = test_file_dir / options.path
      end

      path_to_test_file = test_file_dir / test_file_name

      verb         = "Created"
      dry_run_verb = "create"

      if path_to_test_file.exist?
        if options.overwrite?
          verb         = "Overwrote"
          dry_run_verb = "overwrite"
        else
          error "#{path_to_test_file.relative_path_from(Brut.container.project_root)} exists. Use --overwrite to replace it"
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
      if options.dry_run?
        puts "Will #{dry_run_verb} #{path_to_test_file.relative_path_from(Brut.container.project_root)} with this code:"
        puts
        puts code
      else
        FileUtils.mkdir_p test_file_dir
        File.open(path_to_test_file,"w") do |file|
          file.puts code
        end
        puts "#{verb} #{path_to_test_file.relative_path_from(Brut.container.project_root)}"
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

  class Component < BaseCommand
    def description = "Create a new component and associated test"
    def args_description = "ComponentName"
    def detailed_description = "New components go in the `components/` folder of your app, however using --page will create a 'page private' component.  To do that, the component name must be an inner class of an existing page, for example HomePage::Welcome. This component goes in a sub-folder inside the `pages/` area of your app"

    def opts = super + [
      [ "--page","If set, this component is for a specific page and won't go with the other components"],
    ]

    def run
      if argv.length != 1
        raise "component requires exactly one argument, got #{argv.length}"
      end
      class_name = RichString.new(argv[0]).capitalize(:first_only)
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
      spec_path        = Pathname( (components_specs_dir / relative_path).to_s + ".spec.rb" )

      exists = [
        source_path,
        spec_path,
      ].select(&:exist?)

      if exists.any? && !options.overwrite?
        exists.each do |path|
          error "'#{path.relative_path_from(Brut.container.project_root)}' exists already"
        end
        error "Re-run with --overwrite to overwrite these files"
        return 1
      end

      if options.dry_run?
        puts "FileUtils.mkdir_p #{source_path.dirname}"
        puts "FileUtils.mkdir_p #{spec_path.dirname}"
      else
        FileUtils.mkdir_p source_path.dirname
        FileUtils.mkdir_p spec_path.dirname

        File.open(source_path,"w") do |file|
          file.puts %{class #{class_name} < AppComponent
  def initialize
  end

  def view_template
    h2 { "Welcome to your new template" }
  end
end}
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
      puts "Component source is in #{source_path.relative_path_from(Brut.container.project_root)}"
      puts "Component test is in   #{spec_path.relative_path_from(Brut.container.project_root)}"
      0
    end
  end
  class Page < BaseCommand
    class Route < Brut::FrontEnd::Routing::PageRoute
      def initialize(path_template)
        path_template = "/#{path_template}".gsub(/\/\//,"/")
        super(path_template)
      end
      def locate_handler_class(suffix,preposition, on_missing: :raise)
        begin
          super(suffix,preposition,on_missing: :raise).name.split(/::/)
        rescue Brut::Framework::Errors::NoClassForPath => ex
          class_name_path = ex.class_name_path
          ex.class_name_path
        end
      end
    end
    def description = "Create a new page and associated test"
    def args_description = "page_route"
    def run
      if argv.length != 1
        raise "page requires exactly one argument, got #{argv.length}"
      end
      route = Route.new(argv[0])

      page_class_name    = RichString.from_string(route.handler_class.join("::"))
      page_relative_path = page_class_name.underscorized

      pages_src_dir    = Brut.container.pages_src_dir
      pages_specs_dir  = Brut.container.pages_specs_dir
      i18n_locales_dir = Brut.container.i18n_locales_dir

      page_source_path     = Pathname( (pages_src_dir   / page_relative_path).to_s + ".rb" )
      page_spec_path       = Pathname( (pages_specs_dir / page_relative_path).to_s + ".spec.rb" )
      app_path             = Pathname( Brut.container.app_src_dir / "app.rb" )
      app_translations     = Pathname(  i18n_locales_dir / "en" / "2_app.rb")

      exists = [
        page_source_path,
        page_spec_path,
      ].select(&:exist?)

      if exists.any? && !options.overwrite?
        exists.each do |path|
          error "'#{path.relative_path_from(Brut.container.project_root)}' exists already"
        end
        error "Re-run with --overwrite to overwrite these files"
        return 1
      end

      FileUtils.mkdir_p page_source_path.dirname,     noop: options.dry_run?
      FileUtils.mkdir_p page_spec_path.dirname,       noop: options.dry_run?

      route_code = "page \"#{route.path_template}\""

      initializer_params = route.path_params
      initializer_params_code = if initializer_params.empty?
                                  ""
                                else
                                  "(" + initializer_params.map { "#{it}:" }.join(", ") + ")"
                                end

      page_class_code = %{class #{page_class_name} < AppPage
  def initialize#{initializer_params_code} # add needed arguments here
  end

  def page_template
    h1 { "#{page_class_name} is ready!" }
  end
end}
      page_spec_code = %{require "spec_helper"

RSpec.describe #{page_class_name} do
  it "should have tests" do
    expect(true).to eq(false)
  end
end}

      title = RichString.new(page_class_name).underscorized.humanized.to_s.capitalize
      translations_code = "       \"#{page_class_name}\": {\n         title: \"#{title}\",\n       \},"

      if options.dry_run?
        puts app_path.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{route_code}\n\n"
        puts page_source_path.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{page_class_code}\n\n"
        puts page_spec_path.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{page_spec_code}\n\n"
        puts app_translations.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{translations_code}\n\n"
      else

        File.open(page_source_path,"w")     { it.puts page_class_code }
        File.open(page_spec_path,"w")       { it.puts page_spec_code }

        existing_translations = File.read(app_translations).split(/\n/)
        inserted_translation = false
        File.open(app_translations,"w") do |file|
          existing_translations.each do |line|
            if line =~ /^    pages:\s*{/
              file.puts line
              file.puts translations_code
              inserted_translation = true
            else
              file.puts line
            end
          end
        end
        if !inserted_translation
          error "WARNING: Could not find a place to insert the translation for this page's title"
          error "         The page may not render properly the first time you load it"
        end

        routes_editor = RoutesEditor.new(app_path:,stdout: execution_context.stdout)
        routes_editor.add_route!(route_code:)

        if !routes_editor.found_routes?
          puts "Could not find routes declaration in #{app_path.relative_path_from(Brut.container.project_root)}"
          puts "Please add this to wherever you have defined your routes:\n\n#{route_code}\n\n"
        elsif routes_editor.routes_existed?
          puts "Routes declaration in #{app_path.relative_path_from(Brut.container.project_root)} contained the route defition already"
          puts "Please make sure everything is correct.  Here is the defintion that was not inserted:\n\n#{route_code}"
        end
      end
      puts "Page source is in #{page_source_path.relative_path_from(Brut.container.project_root)}"
      puts "Page test is in   #{page_spec_path.relative_path_from(Brut.container.project_root)}"
      puts "Added title to    #{app_translations.relative_path_from(Brut.container.project_root)}"
      puts "Added route to    #{app_path.relative_path_from(Brut.container.project_root)}"
      0
    end
  end
  class Action < BaseCommand
    class Route < Brut::FrontEnd::Routing::FormRoute
      def initialize(path_template)
        path_template = "/#{path_template}".gsub(/\/\//,"/")
        super(path_template)
      end
      def locate_handler_class(suffix,preposition, on_missing: :raise)
        begin
          super(suffix,preposition,on_missing: :raise).name.split(/::/)
        rescue Brut::Framework::Errors::NoClassForPath => ex
          class_name_path = ex.class_name_path
          ex.class_name_path
        end
      end
    end
    def description = "Create a handler for an action"
    def args_description = "action_route"
    def opts = super + [
      [ "--http-method=METHOD", "If present, the action will be a path available on the given route and this HTTP method. If omitted, this will create an action available via POST" ],
    ]

    def run(form: false)
      if argv.length != 1
        raise "#{self.class.command_name} requires exactly one argument, got #{argv.length}"
      end
      route = Route.new(argv[0])

      form_class_name    = RichString.from_string(route.form_class.join("::"))
      handler_class_name = RichString.from_string(route.handler_class.join("::"))

      relative_path         = form_class_name.underscorized
      handler_relative_path = handler_class_name.underscorized

      forms_src_dir      = Brut.container.forms_src_dir
      handlers_src_dir   = Brut.container.handlers_src_dir
      handlers_specs_dir = Brut.container.handlers_specs_dir

      form_source_path    = Pathname( (forms_src_dir      / relative_path).to_s + ".rb" )
      handler_source_path = Pathname( (handlers_src_dir   / handler_relative_path).to_s + ".rb" )
      handler_spec_path   = Pathname( (handlers_specs_dir / handler_relative_path).to_s + ".spec.rb" )
      app_path            = Pathname( Brut.container.app_src_dir / "app.rb" )

      paths_to_check = [
        handler_source_path,
        handler_spec_path,
      ]
      if form
        paths_to_check << form_source_path
      end

      exists = paths_to_check.select(&:exist?)

      if exists.any? && !options.overwrite?
        exists.each do |path|
          error "'#{path.relative_path_from(Brut.container.project_root)}' exists already"
        end
        error "Re-run with global option --overwrite to overwrite these files"
        return 1
      end

      if form
        FileUtils.mkdir_p form_source_path.dirname, noop: options.dry_run?
      end
      FileUtils.mkdir_p handler_source_path.dirname, noop: options.dry_run?
      FileUtils.mkdir_p handler_spec_path.dirname,   noop: options.dry_run?

      form_code = %{class #{form_class_name} < AppForm
  input :some_field, minlength: 3
end}
      handle_method_code = 'raise "You need to implement your Handler"'
      handler_code = begin
                       handle_params = []
                       if form
                         handle_params << :form
                       end
                       handle_params += route.path_params
                       initializer_params_code = handle_params.map { "#{it}:" }.join(", ")
        %{class #{handler_class_name} < AppHandler
  def initialize(#{initializer_params_code}) # add other args here as needed
  end
  def handle
    #{handle_method_code}
  end
end}
                     end

      spec_code = %{require "spec_helper"

RSpec.describe #{handler_class_name} do
  describe "#handle!" do
    it "needs tests" do
      expect(true).to eq(false)
      # Make sure to call handle! (not handle)
    end
  end
end}

      route_code = if form
                     "form \"#{route.path_template}\""
                   elsif options.http_method.nil?
                     "action \"#{route.path_template}\""
                   else
                     "path \"#{route.path_template}\", method: :#{options.http_method.downcase}"
                   end

      if options.dry_run?
        puts app_path.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{route_code}\n\n"
        if form
          puts form_source_path.relative_path_from(Brut.container.project_root)
          puts "will contain:\n\n#{form_code}\n\n"
        end
        puts handler_source_path.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{handler_code}\n\n"
        puts handler_spec_path.relative_path_from(Brut.container.project_root)
        puts "will contain:\n\n#{spec_code}\n\n"
      else
        class_name_length = [ form_class_name.length, handler_class_name.length, "Spec".length ].max
        printf_string = "%-#{class_name_length}s in %s\n"
        puts "\n\n"
        if form
          execution_context.stdout.printf printf_string,form_class_name,form_source_path.relative_path_from(Brut.container.project_root)
        end
        execution_context.stdout.printf printf_string,handler_class_name, handler_source_path.relative_path_from(Brut.container.project_root)
        execution_context.stdout.printf printf_string,"Spec", handler_spec_path.relative_path_from(Brut.container.project_root)

        routes_editor = RoutesEditor.new(app_path:,stdout: execution_context.stdout)
        routes_editor.add_route!(route_code:)

        if form
          File.open(form_source_path,"w") { it.puts form_code }
        end
        File.open(handler_source_path,"w") { it.puts handler_code }
        File.open(handler_spec_path,"w") { it.puts spec_code }
        if !routes_editor.found_routes?
          puts "Could not find routes declaration in #{app_path.relative_path_from(Brut.container.project_root)}"
          puts "Please add this to wherever you have defined your routes:\n\n#{route_code}\n\n"
        elsif routes_editor.routes_existed?
          puts "Routes declaration in #{app_path.relative_path_from(Brut.container.project_root)} contained the route defition already"
          puts "Please make sure everything is correct.  Here is the defintion that was not inserted:\n\n#{route_code}"
        end
      end
      0
    end
  end

  class Form < Action
    def description = "Create a form and handler"
    def args_description = "form_route"

    def run
      super(form:true)
    end
  end

  class CustomElementTest < BaseCommand
    def description = "Create a test for a custom element in your app"
    def args_description = "path_to_js_files..."
    def run
      if argv.empty?
        error "'custom-element-test' requires one or more files to scaffold a test for"
        return 1
      end

      if argv.any? { |file| Pathname(file).extname != ".js" }
        error "'custom-element-test' must be given only .js files"
        return 1
      end

      files_to_create = argv.map { |arg|
        path = Pathname(arg).expand_path
        relative_path = path.relative_path_from(Brut.container.js_src_dir)
        relative_path_as_spec = relative_path.dirname / (relative_path.basename(relative_path.extname).to_s + ".spec.js")
        spec_path = Brut.container.js_specs_dir / relative_path_as_spec
        [ path, spec_path ]
      }

      existing_files = files_to_create.select { |_,spec|
        spec.exist?
      }

      if existing_files.any? && !options.overwrite?
        relative_paths = existing_files.map { |_,pathname| pathname.relative_path_from(Brut.container.project_root) }
        error "Some files to be generated already exist. Set global option --overwrite to overwrite them:"
        relative_paths.each do |file|
          error file
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
        if options.dry_run?
          puts "Would generate this code:\n\n#{code}"
        else
          File.open(spec_file, "w") do |file|
            file.puts code
          end
        end
      end

      0
    end
  end

  class DbModel < BaseCommand
    def description = "Creates a DB models, factories, and a single placeholder migration"
    def args_description = "model_name..."

    def detailed_description  = "Creates empty versions of the files you'd need to access a database table or tables, along with a migration to, in theory, create those tables. Do note that this will guess at external id prefixes"

    def run
      if argv.length == 0
        return abort_execution("You must provide a model name")
      end
      db_module = ModuleName.from_string("DB")
      actions = argv.map { |arg|
        ModuleName.from_string(arg)
      }.map { |module_name|
        module_name.in_module(db_module)
      }.map do |model_name|
        {
          class_name: model_name.to_s,
          path: model_name.path_from(Brut.container.data_models_src_dir),
          prefix: model_name.parts_of_module[1].to_s[0,2].downcase,
          spec_path: model_name.path_from(Brut.container.data_models_specs_dir, extname: ".spec.rb"),
          factory_path: model_name.path_from(Brut.container.app_specs_dir / "factories", extname: ".factory.rb"),
          factory_name: model_name.parts_of_module[1..-1].map(&:underscorized).join("_"),
        }
      end
      migration_name = "create_" + argv.join("_").gsub(/[^\w]/,"_").gsub(/__/,"_")
      if options.dry_run?
        puts "Would create the following DB models:"
        actions.each do |action|
          puts "#{action[:class_name]}"
          puts "  prefix:  #{action[:prefix]}"
          puts "  in:      #{action[:path]}"
          puts "  spec:    #{action[:spec_path]}"
          puts "  factory: #{action[:factory_path]}"
          puts "     name: #{action[:factory_name]}"

        end
        puts "Would create a migration file"
        puts "  via:   brut db new_migration #{migration_name}"
      else
        system!("brut db new_migration #{migration_name}")
        actions.each do |action|
          FileUtils.mkdir_p action[:path].dirname
          puts "Creating #{action[:class_name]} in #{action[:path].relative_path_from(Brut.container.project_root)}"
          File.open(action[:path].to_s,"w") do |file|
            file.puts %{class #{action[:class_name]} < AppDataModel
  has_external_id :#{action[:prefix]} # !IMPORTANT: Make sure this is unique amongst your DB models
end}
          end
          FileUtils.mkdir_p action[:spec_path].dirname
          puts "Creating spec for #{action[:class_name]} in #{action[:spec_path].relative_path_from(Brut.container.project_root)}"
          File.open(action[:spec_path].to_s,"w") do |file|
            file.puts %{require "spec_helper"
RSpec.describe #{action[:class_name]} do
  # Remove this if you decide to put logic on
  # your model
  implementation_is_trivial
end}
          end
          FileUtils.mkdir_p action[:factory_path].dirname
          puts "Creating factory for #{action[:class_name]} in #{action[:factory_path].relative_path_from(Brut.container.project_root)}"
          File.open(action[:factory_path].to_s,"w") do |file|
            file.puts %{FactoryBot.define do
  factory :#{action[:factory_name]}, class: "#{action[:class_name]}" do
    # Add attributes here
  end
end

}
          end
        end
      end
      0
    end
    
  end

  class RoutesEditor
    def initialize(app_path:,stdout:)
      @app_path       = app_path
      @stdout         = stdout
      @found_routes   = false
      @routes_existed = false
    end

    def found_routes?   = @found_routes
    def routes_existed? = @routes_existed

    def add_route!(route_code:)
      app_contents = File.read(@app_path).split(/\n/)
      File.open(@app_path,"w") do |file|
        in_routes = false
        app_contents.each do |line|
          if line =~ /^  routes do\s*$/
            in_routes = true
          end
          if in_routes && line.include?(route_code)
            @routes_existed = true
          end
          if in_routes && line =~ /^  end\s*$/
            if !@routes_existed
              @stdout.puts "Inserted route into #{@app_path.relative_path_from(Brut.container.project_root)}"
              file.puts "    #{route_code}"
            end
            @found_routes = true
            in_routes = false
          end
          file.puts line
        end
      end
    end
  end
end

