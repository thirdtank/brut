class Brut::CLI::Apps::New::Segments::DockerDeploy < Brut::CLI::Apps::New::Base
  def self.friendly_name = "Generic Docker-based Deployment"
  def self.segment_name = "docker-deploy"

  def initialize(project_root:, templates_dir:)
    @project_root  = project_root
    @templates_dir = templates_dir / "segments" / "DockerDeploy"
  end

  def add!
    operations = copy_files(@templates_dir, @project_root)

    operations.each do |operation|
      operation.call
    end
  end

  def <=>(other)
    if self.class == other.class
      0
    elsif other.class == Brut::CLI::Apps::New::Segments::Sidekiq
      # If both docker and sidekiq segments are activated, we want to do heroku first,
      # since Sidekiq will need to modify it.
      -1
    else
      1
    end
  end
end
