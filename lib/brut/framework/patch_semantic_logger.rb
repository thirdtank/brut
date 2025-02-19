class SemanticLogger::Appender::Async
  # Set the thread created by SemanticLogger as fork safe to avoid
  # a warning.
  #
  # Here is where Puma uses this
  #
  # https://github.com/puma/puma/blob/ca201ef69757f8830b636251b0af7a51270eb68a/lib/puma/cluster.rb#L377
  #
  # Of note, this change is only OK because on_worker_boot is set up to reopen 
  # SemanticLogger's appenders.  Otherwise, the warning is legit.
  #
  def thread_with_puma_magic_variable
    thread = thread_without_puma_magic_variable
    thread.thread_variable_set(:fork_safe, true)
    thread
  end

  alias_method :thread_without_puma_magic_variable, :thread
  alias_method :thread, :thread_with_puma_magic_variable

end
