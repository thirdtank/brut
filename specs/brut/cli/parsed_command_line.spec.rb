require "spec_helper"
require "stringio"

require "brut/cli"

class TestCLIApp < Brut::CLI::Commands::BaseCommand
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
      TestSubCommand.new
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
      TestSubCommand.new
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
      TestSubSubCommand.new
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
        describe "log level" do
          it "defaults to error" do
            parsed_command_line = described_class.new(app_command:, argv: [], env: {})
            expect(parsed_command_line.options.log_level).to eq("error")
          end
          it "sets the log level if specified on command line" do
            argv = ["--log-level", "info" ]
            parsed_command_line = described_class.new(app_command:, argv:, env: {})
            expect(parsed_command_line.options.log_level).to eq("info")
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
