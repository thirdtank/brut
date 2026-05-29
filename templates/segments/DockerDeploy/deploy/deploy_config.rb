# This contains settings for your production Docker setup.
# You own and maintain this file.  It is `require`d by brut deploy docker
class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig

  # Return an array of ProcessDescription instances, that you can
  # create with the `process_description` method.
  #
  # For example, if you have the Sidekiq segment installed, `bin/run sidekiq`
  # runs Sidekiq, so you would implement the method as follows:
  #
  #    def additional_processes = [
  #      process_description("sidekiq", [ "bundle", "exec", "bin/run sidekiq" ]),
  #    ]
  #
  def additional_processes
  end
end
