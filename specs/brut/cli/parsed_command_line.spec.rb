require "spec_helper"
require "stringio"

require "brut/cli"

class TestCLIApp < Brut::CLI::Commands::BaseCommand
  def description = "some description"
  def name = "test_cli_app"
  def opts = [
    [ "--verbose", "be verbose" ],
  ]

  def execute(argv:,options:,stdout:,stderr:,stdin:,env:)
    @argv = argv
    @options = options
  end

  def commands
    @commands ||= [
      TestSubCommand.new,
    ]
  end

  def argv_called = @argv
  def options_called = @options

end
class TestCLIAppWithDefault < Brut::CLI::Commands::BaseCommand
  def description = "some description"
  def opts = [
    [ "--verbose", "be verbose" ],
  ]

  def execute(argv:,options:,stdout:,stderr:,stdin:,env:)
    @argv = argv
    @options = options
  end

  def commands
    @commands ||= [
      TestSubCommand.new,
    ]
  end

  def argv_called = @argv
  def options_called = @options

end

class TestSubCommand < Brut::CLI::Commands::BaseCommand
  def execute(argv:,options:,stdout:,stderr:,stdin:,env:)
    @argv = argv
    @options = options
  end

  def description = "a test sub command"
  def opts = [
    [ "--clean=CLEAN", "do we clean?" ],
  ]

  def argv_called = @argv
  def options_called = @options

  def commands
    @commands ||= [
      TestSubSubCommand.new,
    ]
  end

end

class TestSubSubCommand < Brut::CLI::Commands::BaseCommand
  def execute(argv:,options:,stdout:,stderr:,stdin:,env:)
    @argv = argv
    @options = options
  end

  def description = "a test sub subcommand"
  def opts = [
    [ "--blah=CLEAN", "do we blah?" ],
  ]

  def argv_called = @argv
  def options_called = @options
end

RSpec.describe Brut::CLI::ParsedCommandLine do
  let(:app_command) { TestCLIApp.new }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin)  { StringIO.new }
  describe ".new" do
    context "app options are invalid" do
      context "BRUT_DEBUG is not set" do
        it "command is an OutputErrorCommand" do
          argv = ["--not-supported"]
          parsed_command_line = described_class.new(app_command:, argv:, env: {})
          expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::OutputError)
        end
      end
      context "BRUT_DEBUG is set" do
        it "command is a RaiseErrorCommand" do
          argv = ["--not-supported"]
          parsed_command_line = described_class.new(app_command:, argv:, env: { "BRUT_DEBUG" => "true"})
          expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::RaiseError)
        end
      end
    end
    context "app options are valid" do
      context "remaining argv" do
        it "command is app_command" do
          argv = ["--verbose", "foo" ]
          app_command =TestCLIAppWithDefault.new
          parsed_command_line = described_class.new(app_command:, argv:, env: {})
          expect(parsed_command_line.command).to eq(app_command)
          expect(parsed_command_line.argv).to eq(["foo"])
          expect(parsed_command_line.options.verbose?).to eq(true)
        end
      end
      context "no remaining argv" do
        context "app_command has no default command" do
          it "command is app_command" do
            argv = ["--verbose" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command).to eq(app_command)
            expect(parsed_command_line.argv).to eq([])
            expect(parsed_command_line.options.verbose?).to eq(true)
          end
        end
        describe "project_environment" do
          it "returns a ProjectEnvironment if specified on command line" do
            argv = ["--env", "development" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.project_environment).not_to eq(nil)
            expect(parsed_command_line.project_environment.development?).to eq(true)
          end
          it "outputs an error if the value is not a valid project environment" do
            argv = ["--env", "foobar" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::OutputError)
            expect(parsed_command_line.command.exception.message).to eq("'foobar' is not a valid project environment")
            expect(parsed_command_line.project_environment).to eq(nil)
          end
          it "returns nil if it was no specified" do
            argv = []
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.project_environment).to eq(nil)
          end
        end
        describe "logging to standard output" do
          it "defaults to false" do
            parsed_command_line = described_class.new(app_command:, argv: [], env: {})
            expect(parsed_command_line.options.log_stdout?).to eq(false)
          end
          it "is true if --log-stdout is specified" do
            parsed_command_line = described_class.new(app_command:, argv: ["--log-stdout"], env: {})
            expect(parsed_command_line.options.log_stdout?).to eq(true)
          end
          it "is true if --verbose is specified" do
            parsed_command_line = described_class.new(app_command:, argv: ["--verbose"], env: {})
            expect(parsed_command_line.options.log_stdout?).to eq(true)
          end
          it "is true if --debug is specified" do
            parsed_command_line = described_class.new(app_command:, argv: ["--debug"], env: {})
            expect(parsed_command_line.options.log_stdout?).to eq(true)
          end
          it "is false if --verbose is specified, but --no-log-stdout is set" do
            parsed_command_line = described_class.new(app_command:, argv: ["--no-log-stdout", "--verbose"], env: {})
            expect(parsed_command_line.options.log_stdout?).to eq(false)
          end
          it "is false if --debug is specified, but --no-log-stdout is set" do
            parsed_command_line = described_class.new(app_command:, argv: ["--no-log-stdout", "--debug"], env: {})
            expect(parsed_command_line.options.log_stdout?).to eq(false)
          end
        end
        describe "log file" do
          context "--log-file is set" do
            it "uses that value if set" do
              parsed_command_line = described_class.new(app_command:, argv: ["--log-file","/tmp/blah/crud.log"], env: {})
              expect(parsed_command_line.options.log_file.class).to eq(Pathname)
              expect(parsed_command_line.options.log_file.to_s).to eq("/tmp/blah/crud.log")
            end
          end
          context "--log-file is omitted" do
            context "XDG_STATE_HOME is set" do
              it "uses $XDG_STATE_HOME/brut/«app_name».log if XDG_STATE_HOME is set" do
                parsed_command_line = described_class.new(app_command:, argv: [], env: { "XDG_STATE_HOME" => "/tmp/blah"})
                expect(parsed_command_line.options.log_file.class).to eq(Pathname)
                expect(parsed_command_line.options.log_file.to_s).to eq("/tmp/blah/brut/test_cli_app.log")
              end
            end
            context "XDG_STATE_HOME is not set" do
              context "HOME is set" do
                context "HOME is writable" do
                  it "defaults to ~/.local/state/brut/«app_name».log" do
                    parsed_command_line = described_class.new(app_command:, argv: [], env: { "HOME" => "/home/appuser"})
                    expect(parsed_command_line.options.log_file.to_s).to eq("/home/appuser/.local/state/brut/test_cli_app.log")
                  end
                end
                context "HOME is not writable" do
                  it "does not log to a file" do
                    parsed_command_line = described_class.new(app_command:, argv: [], env:  { "HOME" => "/" })
                    expect(parsed_command_line.options.log_file).to eq(nil)
                  end
                end
              end
              context "HOME is not set" do
                it "does not log to a file" do
                  parsed_command_line = described_class.new(app_command:, argv: [], env: {})
                  expect(parsed_command_line.options.log_file).to eq(nil)
                end
              end
            end
          end 
        end
        describe "log level" do
          it "defaults to info" do
            parsed_command_line = described_class.new(app_command:, argv: [], env: {})
            expect(parsed_command_line.options.log_level).to eq("info")
          end
          it "--quiet sets log level to error" do
            parsed_command_line = described_class.new(app_command:, argv: ["--quiet"], env: {})
            expect(parsed_command_line.options.log_level).to eq("error")
          end
          it "--debug sets log level to debug" do
            parsed_command_line = described_class.new(app_command:, argv: ["--debug"], env: {})
            expect(parsed_command_line.options.log_level).to eq("debug")
          end
          it "--verbose sets log level to debug" do
            parsed_command_line = described_class.new(app_command:, argv: ["--verbose"], env: {})
            expect(parsed_command_line.options.log_level).to eq("debug")
          end
          context "using --log-level" do
            it "sets the log level if specified on command line" do
              argv = ["--log-level", "info" ]
              parsed_command_line = described_class.new(app_command:, argv:, env: {})
              expect(parsed_command_line.options.log_level).to eq("info")
            end
            it "supercedes --verbose" do
              argv = ["--log-level", "info", "--verbose" ]
              parsed_command_line = described_class.new(app_command:, argv:, env: {})
              expect(parsed_command_line.options.log_level).to eq("info")
            end
            it "supercedes --debug" do
              argv = ["--log-level", "info", "--debug" ]
              parsed_command_line = described_class.new(app_command:, argv:, env: {})
              expect(parsed_command_line.options.log_level).to eq("info")
            end
            it "supercedes --quiet" do
              argv = ["--log-level", "info", "--quiet" ]
              parsed_command_line = described_class.new(app_command:, argv:, env: {})
              expect(parsed_command_line.options.log_level).to eq("info")
            end
          end
          it "outputs an error if the value is not a valid log level" do
            argv = ["--log-level", "foobar" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::OutputError)
            expect(parsed_command_line.command.exception.class).to eq(OptionParser::InvalidArgument)
          end
        end
      end
      context "subcommand" do
        context "found" do
          context "options are valid" do
            it "command is the subcommand" do
              argv = ["--verbose", "test_sub_command", "--clean", "yes", "foo" ]
              expected_command = app_command.commands.detect { it.name == "test_sub_command" }
              confidence_check { expect(expected_command).not_to eq(nil) }

              parsed_command_line = described_class.new(app_command:, argv:, env: {})
              expect(parsed_command_line.command).to eq(expected_command)
              aggregate_failures do
                expect(parsed_command_line.argv).to eq(["foo"])
                expect(parsed_command_line.options.verbose?).to eq(true)
                expect(parsed_command_line.options.clean?).to eq(true)
              end
            end
          end
        end
        context "options are not valid" do
          it "command is an OutputErrorCommand" do
            argv = ["--verbose", "test_sub_command", "--cleansed", "yes", "foo" ]
            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::OutputError)
            expect(parsed_command_line.command.exception.message).to include("invalid option: --cleansed")
          end
        end
        context "not found" do
          it "command is app_command with the remainder as argv" do
            argv = ["--verbose", "not_a_sub_command", "--cleansed", "yes", "foo" ]

            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command).to eq(app_command)
            aggregate_failures do
              expect(parsed_command_line.argv).to eq([ "not_a_sub_command", "--cleansed", "yes", "foo" ])
              expect(parsed_command_line.options.verbose?).to eq(true)
            end
          end
        end
      end
      context "sub-subcommand" do
        context "found" do
          context "options are valid" do
            it "command is the sub-sub command" do
              argv = ["--verbose", "test_sub_command", "test_sub_sub_command", "--blah", "yes", "foo" ]

              expected_command = app_command.commands.detect { it.name == "test_sub_command" }
              confidence_check { expect(expected_command).not_to eq(nil) }
              expected_command = expected_command.commands.detect { it.name == "test_sub_sub_command" }
              confidence_check { expect(expected_command).not_to eq(nil) }

              parsed_command_line = described_class.new(app_command:, argv:, env: {})
              expect(parsed_command_line.command).to eq(expected_command)
              aggregate_failures do
                expect(parsed_command_line.argv).to eq(["foo"])
                expect(parsed_command_line.options.verbose?).to eq(true)
                expect(parsed_command_line.options.blah).to eq("yes")
              end
            end
          end
        end
        context "not found" do
          it "command is the subcommand it did find" do
            argv = ["--verbose", "test_sub_command", "not_a_sub_command", "yes", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command).to eq(expected_command)
            aggregate_failures do
              expect(parsed_command_line.argv).to eq(["not_a_sub_command", "yes", "foo"])
              expect(parsed_command_line.options.verbose?).to eq(true)
            end
          end
          it "returns an error if the flags are for the sub-sub command it didn't find" do
            argv = ["--verbose", "test_sub_command", "not_a_sub_command", "--blah", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::OutputError)
          end
        end
      end
    end
    context "help requested" do
      context "via --help to the app" do
        context "no subcommand" do
          it "returns HelpCommand" do
            argv = ["--verbose", "--help", "foo" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(app_command.description)
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
        context "with a subcommand" do
          it "shows help for that subcommand" do
            argv = ["--help", "test_sub_command", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(expected_command.description)
            expect(help_text).to include("do we clean")
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
        context "with a nested subcommand" do
          it "shows help for that nested subcommand" do
            argv = ["--help", "test_sub_command", "test_sub_sub_command", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }
            expected_command = expected_command.commands.detect { it.name == "test_sub_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})

            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(expected_command.description)
            expect(help_text).to include("do we blah")
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
      end
      context "via --help to the command" do
        context "with a subcommand" do
          it "shows help for that subcommand" do
            argv = ["test_sub_command", "--help", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})

            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help),parsed_command_line.command.inspect
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(expected_command.description)
            expect(help_text).to include("do we clean")
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
        context "with a nested subcommand" do
          it "shows help for that nested subcommand" do
            argv = ["test_sub_command", "test_sub_sub_command", "--help", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }
            expected_command = expected_command.commands.detect { it.name == "test_sub_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})

            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(expected_command.description)
            expect(help_text).to include("do we blah")
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
      end
      context "via the help command" do
        context "no subcommand" do
          it "shows help" do
            argv = ["--verbose", "help", "foo" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})

            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(app_command.description)
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
        context "with a subcommand" do
          it "shows help for that subcommand" do
            argv = ["help", "test_sub_command", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: { "BRUT_DEBUG" => "true" })

            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(expected_command.description)
            expect(help_text).to include("do we clean")
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
        context "with a nested subcommand" do
          it "shows help for that nested subcommand" do
            argv = ["help", "test_sub_command", "test_sub_sub_command", "foo" ]

            expected_command = app_command.commands.detect { it.name == "test_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }
            expected_command = expected_command.commands.detect { it.name == "test_sub_sub_command" }
            confidence_check { expect(expected_command).not_to eq(nil) }

            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.command.class).to eq(Brut::CLI::Commands::Help)
            help_text = parsed_command_line.command.option_parser.to_s

            expect(help_text).to include(expected_command.description)
            expect(help_text).to include("do we blah")
            expect(help_text).to include("be verbose")
            expect(help_text).to include("Project environment")
          end
        end
      end
    end
  end
end
