require "spec_helper"
require "pathname"
require "fileutils"
require "brut/cli"
require "brut/spec_support/e2e_test_server"

RSpec.describe Brut::CLI::Apps::Test do
  let(:test_container) { Brut::Framework::Container.new }
  let(:app_specs_dir)  { "/fake/brut-app/specs" }
  let(:app_src_dir)    { "/fake/brut-app/app" }

  before do
    allow(Brut).to receive(:container).and_return(test_container)
    test_container.store("app_specs_dir", Pathname, "", Pathname(app_specs_dir))
    test_container.store("app_src_dir", Pathname, "", Pathname(app_src_dir))
  end

  describe described_class::Run, cli_command: true do
    context "not rebuilding the DB" do
      context "not setting a seed" do
        context "no argv" do
          it "runs rspec without any arguments" do
            execution_context = test_execution_context
            result = described_class.new.execute(execution_context)
            expect(result).to eq(0)
            expect(execution_context).to have_executed([
              "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag ~e2e -P '**/*.spec.rb' /fake/brut-app/specs/",
            ])
          end
        end
        context "argv set" do
          it "runs rspec with the given arguments, shell-escaping them" do
            execution_context = test_execution_context(argv: [ "foo", "bar's" ])
            result = described_class.new.execute(execution_context)
            expect(result).to eq(0)
            expect(execution_context).to have_executed([
              "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag ~e2e -P '**/*.spec.rb' \"foo\" \"bar\\'s\"",
            ])
          end
        end
      end
      context "setting a seed" do
        it "runs rspec with that seed" do
          execution_context = test_execution_context(options: { seed: "1234" })
          result = described_class.new.execute(execution_context)
          expect(result).to eq(0)
          expect(execution_context).to have_executed([
            "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag ~e2e -P '**/*.spec.rb' --seed 1234 /fake/brut-app/specs/",
          ])
        end
      end
    end
    context "rebuilding the DB" do
      it "runs brut db rebuild before and after" do
        execution_context = test_execution_context(options: { "rebuild": true, "rebuild-after": true })
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(execution_context).to have_executed([
          "brut db rebuild --env=test",
          "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag ~e2e -P '**/*.spec.rb' /fake/brut-app/specs/",
          "brut db rebuild --env=test",
        ])
      end
    end
  end
  describe described_class::E2e, cli_command: true do

    let(:test_server) { instance_double(Brut::SpecSupport::E2ETestServer) }
    before do
      allow(Brut::SpecSupport::E2ETestServer).to receive(:instance).and_return(test_server)
      allow(test_server).to receive(:start)
      allow(test_server).to receive(:stop)
    end

    context "not rebuilding the DB" do
      context "not setting a seed" do
        context "no argv" do
          it "starts the test server, runs rspec without any arguments, then stops the test server" do
            execution_context = test_execution_context
            result = described_class.new.execute(execution_context)
            expect(result).to eq(0)
            expect(execution_context).to have_executed([
              "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag e2e -P '**/*.spec.rb' /fake/brut-app/specs/",
            ])
            expect(test_server).to have_received(:start)
            expect(test_server).to have_received(:stop)
          end
        end
        context "argv set" do
          it "runs rspec with the given arguments, shell-escaping them, then stops the test server" do
            execution_context = test_execution_context(argv: [ "foo", "bar's" ])
            result = described_class.new.execute(execution_context)
            expect(result).to eq(0)
            expect(execution_context).to have_executed([
              "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag e2e -P '**/*.spec.rb' \"foo\" \"bar\\'s\"",
            ])
            expect(test_server).to have_received(:start)
            expect(test_server).to have_received(:stop)
          end
        end
      end
      context "setting a seed" do
        it "runs rspec with that seed, then stops the test server" do
          execution_context = test_execution_context(options: { seed: "1234" })
          result = described_class.new.execute(execution_context)
          expect(result).to eq(0)
          expect(execution_context).to have_executed([
            "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag e2e -P '**/*.spec.rb' --seed 1234 /fake/brut-app/specs/",
          ])
          expect(test_server).to have_received(:start)
          expect(test_server).to have_received(:stop)
        end
      end
    end
    context "rebuilding the DB" do
      it "runs brut db rebuild before and after" do
        execution_context = test_execution_context(options: { "rebuild": true, "rebuild-after": true })
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(execution_context).to have_executed([
          "brut db rebuild --env=test",
          "bin/rspec -I /fake/brut-app/specs -I /fake/brut-app/app --tag e2e -P '**/*.spec.rb' /fake/brut-app/specs/",
          "brut db rebuild --env=test",
        ])
        expect(test_server).to have_received(:start)
        expect(test_server).to have_received(:stop)
      end
    end
  end
  describe described_class::Js, cli_command: true do

    let(:js_specs_dir) { "/fake/brut-app/specs/js" }

    before do
      test_container.store("js_specs_dir", Pathname, "", Pathname(js_specs_dir))
    end

    context "building assets" do
      it "builds assets, then runs mocha" do
        execution_context = test_execution_context
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(execution_context).to have_executed([
          [ { "RACK_ENV" => "test" }, "brut build-assets all" ],
          [ { "NODE_DISABLE_COLORS" => "1" },"npx mocha /fake/brut-app/specs/js --no-color --extension 'spec.js' --recursive" ],
        ])
      end
    end
    context "not building assets" do
      it "does not builds assets, just runs mocha" do
        execution_context = test_execution_context(options: { "build-assets": false })
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(execution_context).to have_executed([
          [ { "NODE_DISABLE_COLORS" => "1" },"npx mocha /fake/brut-app/specs/js --no-color --extension 'spec.js' --recursive" ],
        ])
      end
    end
  end
  describe described_class::Audit do
  end
end
