# This contains settings for your production Docker setup.
# You own and maintain this file.  It is `require`d by brut deploy docker
class DockerConfig

  # Can return a Docker platform is your deployment platform is not
  # linux/amd64. Note that --platform will override this value.
  def platform = nil

  # Return a Hash of additional images to run, beyond "web" and "release".
  #
  # The format of this Hash is:
  #
  # {
  #   *image name* => {
  #     cmd: *command line for Dockerfile RUN directive*,
  #   }
  # }
  #
  # For example, if you have the Sidekiq segment installed, `bin/run sidekiq`
  # runs Sidekiq, so you would return this hash:
  #
  # {
  #   "sidekiq" => {
  #     cmd: "bin/run sidekiq",
  #   }
  # }
  #
  def additional_images
  end
end
