# This is entirely to allow the integration test to run
# that verifies you have Sidekqi working and the segment was
# installed correctly.  Once you have created a real job for
# your app and done whatever testing you need, please delete
# this job and the integration test.
class ExampleJob < AppJob
  def perform(path_to_file, contents)
    File.open(path_to_file, "w") do |f|
      f.puts(contents)
    end
  end
end
