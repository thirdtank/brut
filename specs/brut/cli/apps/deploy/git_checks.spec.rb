require "spec_helper"
require "brut/cli"

RSpec.describe Brut::CLI::Apps::Deploy::GitChecks do
  let(:executor) { instance_double(Brut::CLI::Executor) }

  subject(:git_checks) { described_class.new(executor:) }

  before do
    allow(executor).to receive(:system!).with("git status")
  end

  context "On main branch" do
    context "No local changes" do
      context "we have remote's changes" do
        context "remote has our changes" do
        end
        context "remote does not have our changes" do
          it "returns an error" do
            allow(executor).to receive(:system!).with("git branch --show-current").and_yield("main")
            allow(executor).to receive(:system!).with("git diff-index --name-only HEAD --").and_yield("")
            allow(executor).to receive(:system!).with("git rev-list --left-right --count origin/main...main").and_yield("0\t4")
            check_results = git_checks.check!
            expect(check_results.errors?).to eq(true)
            expect(check_results.errors["main-branch"]).to eq(nil)
            expect(check_results.errors["local-changes"]).to eq(nil)
            expect(check_results.errors["remote-behind"]).to match(/4 commits.*not pushed/)
          end
        end
      end
      context "we do not have remote's changes" do
        it "returns an error" do
          allow(executor).to receive(:system!).with("git branch --show-current").and_yield("main")
          allow(executor).to receive(:system!).with("git diff-index --name-only HEAD --").and_yield("")
          allow(executor).to receive(:system!).with("git rev-list --left-right --count origin/main...main").and_yield("4\t0")
          check_results = git_checks.check!
          expect(check_results.errors?).to eq(true)
          expect(check_results.errors["main-branch"]).to eq(nil)
          expect(check_results.errors["local-changes"]).to eq(nil)
          expect(check_results.errors["remote-ahead"]).to match(/4 commits.*in origin/)
        end
      end
    end
    context "local changes" do
      it "returns an error" do
        allow(executor).to receive(:system!).with("git branch --show-current").and_yield("main")
        allow(executor).to receive(:system!).with("git diff-index --name-only HEAD --").and_yield("foo.rb\nbar.js\n")
        check_results = git_checks.check!
        expect(check_results.errors?).to eq(true)
        expect(check_results.errors["main-branch"]).to eq(nil)
        expect(check_results.errors["local-changes"]).to match(/foo.rb/m)
        expect(check_results.errors["local-changes"]).to match(/bar.js/m)
      end
    end
  end
  context "Not on main branch" do
    it "returns an error" do
      allow(executor).to receive(:system!).with("git branch --show-current").and_yield("foo")
      check_results = git_checks.check!
      expect(check_results.errors?).to eq(true)
      expect(check_results.errors["main-branch"]).to match(/foo/)
    end
  end
end
