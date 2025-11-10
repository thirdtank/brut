require "shellwords"
require "brut/cli"

class Brut::CLI::Apps::Test < Brut::CLI::App
  description "Run and audit tests of the app"
  default_command :run

  def before_execute
    ENV["RACK_ENV"] = "test"
  end

  class Run < Brut::CLI::Command
    description "Run non-e2e tests"
    opts.on("--[no-]rebuild", "If true, test database is rebuilt before tests are run (default false)")
    opts.on("--[no-]rebuild-after", "If true, test database is rebuilt after tests are run (default false)")
    opts.on("--seed SEED", "Set the random seed to allow duplicating a test run")
    args "specs_to_run..."
    env_var("LOGGER_LEVEL_FOR_TESTS",purpose: "Can be set to debug, info, warn, error, or fatal to control logging during tests. Defaults to 'warn' to avoid verbose test output")
    env_var("RSPEC_WARNINGS", purpose: "If set to 'true', configures RSpec warnings for the test run. NOTE: this is used in the app's spec_helper.rb so could've been removed")
    env_var("RSPEC_PROFILE_EXAMPLES", purpose: "If set to any value, it is converted to an int and set as RSpec's number of examples to profile. NOTE: this is used in the app's spec_helper.rb so could've been removed")


    def rspec_command
      parts = [
        "bin/rspec",
        "-I", Brut.container.app_specs_dir,
        "-I", Brut.container.app_src_dir,
        "-I lib/", # not needed when Brut is gemified
        rspec_cli_args,
        "-P \"**/*.spec.rb\"",
      ]
      if options.seed
        parts << "--seed #{options.seed}"
      end
      parts.join(" ")
    end

    def rspec_cli_args = "--tag ~e2e"

    def rebuild_by_default?       = false
    def rebuild_after_by_default? = false

    def execute
      Brut.container.sequel_db_handle.disconnect
      if options.rebuild?(default: rebuild_by_default?)
        Brut.container.instrumentation.span("schema.rebuild.before") do
          out.puts "Rebuilding test database schema"
          system! "bin/db rebuild --env=test"
        end
      end
      Brut.container.instrumentation.span("tests.run") do |span|
        if args.empty?
          span.add_prefixed_attributes("brut.cli.test", tests: :all)
          out.puts "Running all tests"
          system! "#{rspec_command} #{Brut.container.app_specs_dir}/"
        else
          span.add_prefixed_attributes("brut.cli.test", tests: args.length)
          test_args = args.map { |_|
            '"' + Shellwords.escape(_) + '"'
          }.join(" ")
          system! "#{rspec_command} #{test_args}"
        end
      end
      if options.rebuild_after?(default: rebuild_after_by_default?)
        Brut.container.instrumentation.span("schema.rebuild.after") do
          out.puts "Re-Rebuilding test database schema"
          system! "bin/db rebuild --env=test"
        end
      end
      0
    end
  end
  class E2e < Run
    description "Run e2e tests"
    opts.on("--[no-]rebuild", "If true, test database is rebuilt before tests are run (default true)")
    opts.on("--[no-]rebuild-after", "If true, test database is rebuilt after tests are run (default true)")
    opts.on("--seed SEED", "Set the random seed to allow duplicating a test run")
    args "specs_to_run..."
    env_var("E2E_RECORD_VIDEOS",purpose: "If set to 'true', videos of each test run are saved in `./tmp/e2e-videos`")
    env_var("E2E_SLOW_MO",purpose: "If set to, will attempt to slow operations down by this many milliseconds")
    env_var("E2E_TIMEOUT_MS",purpose: "ms to wait for any browser activity before failing the test. And here you didn't think you'd get away without using sleep in browse-based tests?")
    env_var("LOGGER_LEVEL_FOR_TESTS",purpose: "Can be set to debug, info, warn, error, or fatal to control logging during tests. Defaults to 'warn' to avoid verbose test output")
    env_var("RSPEC_WARNINGS", purpose: "If set to 'true', configures RSpec warnings for the test run. NOTE: this is used in the app's spec_helper.rb so could've been removed")
    env_var("RSPEC_PROFILE_EXAMPLES", purpose: "If set to any value, it is converted to an int and set as RSpec's number of examples to profile. NOTE: this is used in the app's spec_helper.rb so could've been removed")

    def rspec_cli_args = "--tag e2e"
    def rebuild_by_default?       = true
    def rebuild_after_by_default? = true
  end
  class Js < Brut::CLI::Command
    description "Run JavaScript unit tests"
    opts.on("--[no-]build-assets","Build all assets before running the tests")
    def execute
      if options.build_assets?
        system!({ "RACK_ENV" => "test" }, "bin/build-assets")
      end
      system!({ "NODE_DISABLE_COLORS" => "1" },"npx mocha #{Brut.container.js_specs_dir} --no-color --extension 'spec.js' --recursive")
      0
    end
  end
  class Audit < Brut::CLI::Command
    description "Audits all of the app's classes to see if test files exist"

    opts.on("--ignore PATH[,PATH]","Ignore any files in these paths, relative to app root",Array)
    opts.on("--type TYPE","Only audit this type of file")
    opts.on("--show-scaffold","If set, shows the command to scaffold the missing tests")

    def execute
      app_files = Dir["#{Brut.container.app_src_dir}/**/*"].select { |file|
        if file.start_with?(Brut.container.app_specs_dir.to_s)
          false
        elsif Pathname(file).extname != ".rb"
          false
        else
          true
        end
      }
      audit = app_files.map { |file|
        Pathname(file)
      }.select { |pathname|
        relative_to_root = pathname.relative_path_from(Brut.container.project_root)
        if options.ignore(default: []).include?(relative_to_root.to_s)
          false
        else
          true
        end
      }.map { |pathname|
        relative = pathname.relative_path_from(Brut.container.app_src_dir)
        test_file = Brut.container.project_root / "specs" / relative.dirname / "#{relative.basename(relative.extname)}.spec.rb"
        hash = {
          source_file: pathname.relative_path_from(Brut.container.project_root),
          test_file: test_file,
          test_expected: true,
        }
        if pathname.fnmatch?( (Brut.container.components_src_dir / "**").to_s )
          if pathname.basename.to_s == "app_component.rb" || 
             pathname.basename.to_s == "custom_element_registration.rb"
            hash[:type] = :infrastructure
            hash[:test_expected] = false
          else
            hash[:type] = :component
          end
        elsif pathname.fnmatch?( (Brut.container.forms_src_dir / "**").to_s )
          if pathname.basename.to_s == "app_form.rb"
            hash[:type] = :infrastructure
          else
            hash[:type] = :form
          end
          hash[:test_expected] = false
        elsif pathname.fnmatch?( (Brut.container.handlers_src_dir / "**").to_s )
          if pathname.basename.to_s == "app_handler.rb"
            hash[:type] = :infrastructure
            hash[:test_expected] = false
          else
            hash[:type] = :handler
          end
        elsif pathname.fnmatch?( (Brut.container.pages_src_dir / "**").to_s )
          if pathname.basename.to_s == "app_page.rb"
            hash[:type] = :infrastructure
            hash[:test_expected] = false
          else
            hash[:type] = :page
          end
        elsif pathname.fnmatch?( (Brut.container.back_end_src_dir / "**").to_s )
          type = pathname.parent.basename.to_s
          if pathname.basename.to_s == "app_#{type}.rb" ||
             type == "back_end" ||
             type == "seed" ||
             type == "migrations" ||
             type == "segments" ||
             pathname.basename.to_s == "app_data_model.rb" ||
             pathname.basename.to_s == "app_job.rb" ||
             pathname.basename.to_s == "db.rb"

            hash[:type] = :infrastructure
            hash[:test_expected] = false
          else
            hash[:type] = pathname.relative_path_from(Brut.container.back_end_src_dir).dirname
          end
        else
          hash[:type] = :other
          hash[:test_expected] = false
        end
        hash
      }.compact.sort_by { it[:type].to_s + it[:source_file].to_s }

      files_missing = []
      printed_header = false
      audit.each do |file_audit|
        if !file_audit[:test_file].exist?
          if options.type.nil? || file_audit[:type] == options.type.to_sym
            if file_audit[:test_expected]
              files_missing << file_audit[:source_file]
              if !printed_header
                out.puts "These files are missing tests:"
                out.puts ""
                out.printf "%-25s   %s\n","Type", "Path"
                out.puts "-------------------------------------------"
                printed_header = true
              end
              out.puts "#{file_audit[:type].to_s.ljust(25)} - #{file_audit[:source_file]}"
            end
          end
        end
      end
      if files_missing.empty?
        out.puts "All tests exists!"
        0
      else
        if options.show_scaffold?
          out.puts
          files_missing_args = files_missing.map { |file|
            '             "' + Shellwords.escape(file.to_s) + '"'
          }.join(" \\\n")

          out.puts "Run this command to generate empty tests:\n\nbin/scaffold test \\\n#{files_missing_args}"
        end
        1
      end
    end
  end
end

