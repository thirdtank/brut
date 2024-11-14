require "brut/cli"

class Brut::CLI::Apps::Scaffold < Brut::CLI::App
  description "Create scaffolds of various files to help develop more quckly"
  opts.on("--overwrite", "If set, any files that exists already will be overwritten by new scaffolds")
  opts.on("--dry-run", "If set, no files are changed. You will see output of what would happen without this flag")

  def before_execute
    ENV["RACK_ENV"] = "development"
  end

  class Test < Brut::CLI::Command
    description "Create a test for a given file in the app"
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
