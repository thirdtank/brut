RSpec::Matchers.define :have_executed do |commands|
  match do |execution_context|
    commands.all? { |command|
      if command.kind_of?(Regexp)
        execution_context.executor.commands_executed.any? { it.kind_of?(String) && it.match(command) }
      else
        execution_context.executor.commands_executed.include?(command)
      end
    }
  end

  failure_message do |execution_context|
    not_executed  = commands.reject { |command|
      if command.kind_of?(Regexp)
        execution_context.executor.commands_executed.any? { it.kind_of?(String) && it.match(command) }
      else
        execution_context.executor.commands_executed.include?(command)
      end
    }

    "Expected these commands to be executed, but they were not:\n#{format_system_args(not_executed)}\nAll executed commands:\n#{format_system_args(execution_context.executor.commands_executed)}"
  end
  def format_system_args(args)
    args.map { |arg|
      if arg.kind_of?(String)
        arg.to_s
      elsif arg.kind_of?(Regexp)
        "Matching /#{arg.source}/"
      else
        "[" + arg.map(&:inspect).join(", ") + "]"
      end
    }.join("\n")
  end

end
