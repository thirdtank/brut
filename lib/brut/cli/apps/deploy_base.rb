require "brut/cli"

class Brut::CLI::Apps::DeployBase < Brut::CLI::App
  def before_execute
    ENV["RACK_ENV"] = "production"
  end

  class GitChecks
    def initialize(out:, err:, executor:, warn_only: false)
      @out       = out
      @err       = err
      @executor  = executor
      @warn_only = warn_only
    end

    def check!
      require_main_branch!
      require_no_local_changes!
      require_pushed_to_main!
    end

  private

    def require_main_branch!
      # XXX: This should be put into executor
      current_branch = `git branch --show-current`.strip.chomp

      if current_branch != "main"
        @err.puts "You are not on the 'main' branch, but on the '#{current_branch}' branch"
        @err.puts "You may only deploy from the 'main' branch"
        if @warn_only
          @err.puts "Ignoring"
          return
        else
          exit 1
        end
      end
    end

    def require_no_local_changes!
      @out.puts "Running 'git status' to reset local caches to account for Docker<->host oddities"
      @executor.system!("git status")
      local_changes = `git diff-index --name-only HEAD --`
      if local_changes.strip != ""
        @err.puts "You have local changes:"
        local_changes.split(/\n/).each do |change|
          @err.puts "    #{change}"
        end
        @err.puts "Commit these, run bin/ci, then push to origin/main"
        if @warn_only
          @err.puts "Ignoring"
          return
        else
          exit 1
        end
      end
    end

    def require_pushed_to_main!
      # XXX: This should be put into executor
      git_status = `git rev-list --left-right --count origin/main...main`.strip.chomp
      remote_ahead, local_ahead = git_status.split(/\t/,2).map(&:to_i)

      if remote_ahead != 0
        @err.puts "There are commits in origin you don't have. Pull those in, re-run bin/ci, THEN deploy"
        if @warn_only
          @err.puts "Ignoring"
          return
        else
          exit 1
        end
      end

      if local_ahead != 0
        @out.puts "You have not pushed to origin. Do that before deploying"
        if @warn_only
          @err.puts "Ignoring"
          return
        else
          exit 1
        end
      end
    end
  end
end

