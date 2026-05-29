# Describes your app's need for deployment, which can drive
# the automatic deploy system.  You must subclass this in
# deploy/deploy_config.rb.  This class is used in a somewhat
# isolated environment, so you will not have access to your
# app's Brut configuration or any of your app's code.
# To say it another way, this is a way to store
# configuration information without having to use YAML. You're welcome.
class Brut::CLI::Apps::Deploy::DeployConfig

  # Override this to push to another registory
  def registry_hostname = nil

  # Returns the Docker platform for which the images should be built
  def platform = "linux/amd64"

  # Returns a hash where each key is the name of a process 
  # you wish to run, other than the default, 'web'.
  # The keys are largely arbitrary and for documentation purposes,
  # however you are advised to make them ASCII alphanumerics only
  # with no whitespace.
  #
  # The values of each key should be an instance `ProcessDescription`.
  #
  # @example Running Sidekiq
  #
  #    class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig
  #      def additional_processes = [
  #        ProcessDescription.new(name: "sidekiq", cmd: "bin/run sidekiq")
  #      ]
  #    end
  #
  # 
  def additional_processes = []

  # Returns all processes this app needs in production.
  # Generally, do not override this since it configures your
  # web process.  Override {#additional_processes} instead.
  def processes = [
    process_description("web", ["bundle", "exec", "bin/run"])
  ] + (additional_processes || [])

  private def process_description(name,cmd)
    ProcessDescription.new(name:, cmd:)
  end


  # Describes a process you wish to run in production.
  class ProcessDescription

    attr_reader :name, :cmd

    def initialize(name:, cmd:)
      @name = name
      @cmd = Array(cmd)
    end

    def cmd_directive
      "CMD [ " + @cmd.map { "\"#{it}\"" }.join(", ") + " ]"
    end

  end
end
