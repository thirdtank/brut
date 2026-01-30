require "spec_helper"
require "timeout"

# This test will ensure that Sidekiq segment was installed
# correctly and your app can use Sidekiq. Once you have
# created a real job for your app, delete ExampleJob and this test.
RSpec.describe "Sidekiq is working", e2e: true do
  it "processes jobs using the real Sidekiq server" do
    # ExampleJob will write contents to a file.  This 
    # test will delete that fail, queue the job, then
    # wait up to 5 seconds for the job to run and create
    # the file with the contents.  This should be more than
    # enough time.
    file = Brut.container.tmp_dir / "sidekiq_test.txt"
    if file.exist?
      file.delete
    end

    # If the file still exists at this point, the test
    # will pass even if Sidekiq is not working.
    confidence_check { expect(file.exist?).to eq(false) }

    ExampleJob.perform_async(file.to_s, "test content for file")
    queue_name = ExampleJob.sidekiq_options["queue"]
    expect {
      Timeout.timeout(5) do
        loop do
          if file.exist?
            break
          end
          sleep 0.1
        end
      end
    }.not_to raise_error
    content = File.read(file)
    expect(content).to eq("test content for file\n")
  end
end
