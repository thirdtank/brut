class Brut::CLI::Apps::Deploy::GitChecks
  def initialize(executor:)
    @executor = executor
  end
  class Results
    attr_reader :errors
    def initialize(errors = {})
      @errors = errors
    end
    def errors? = errors.any?
  end
  def check!
    branch = ""
    @executor.system!("git branch --show-current") do |output|
      branch << output
    end
    branch = branch.strip.chomp
    if branch != "main"
      return Results.new("main-branch" => "You are on branch '#{branch}', but should be on branch 'main'")
    end

    @executor.system!("git status") do |*| # reset local caches to account for Docker/host wierdness
      # ignore
    end
    local_changes = ""
    @executor.system!("git diff-index --name-only HEAD --") do |output|
      local_changes << output
    end
    if local_changes.strip != ""
      return Results.new("local-changes" => "The following files have not been checked in: #{local_changes}")
    end

    rev_list = ""
    @executor.system!("git rev-list --left-right --count origin/main...main") do |output|
      rev_list << output
    end
    remote_ahead, local_ahead = rev_list.strip.chomp.split(/\t/,2).map(&:to_i)
    if remote_ahead != 0
      if remote_ahead == 1
        return Results.new("remote-ahead" => "There is 1 commit in origin you don't have")
      else
        return Results.new("remote-ahead" => "There are #{remote_ahead} commits in origin you don't have")
      end
    end
    if local_ahead != 0
      if local_ahead == 1
        return Results.new("remote-behind" => "There is 1 commit not pushed to origin")
      else
        return Results.new("remote-behind" => "There are #{local_ahead} commits not pushed to origin")
      end
    end
    Results.new
  end
end
