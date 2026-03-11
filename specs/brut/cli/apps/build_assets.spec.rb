require "spec_helper"
require "tmpdir"
require "pathname"
require "fileutils"
require "brut/cli"

RSpec.describe Brut::CLI::Apps::BuildAssets, cli_command: true do
  let(:test_container) { Brut::Framework::Container.new }
  let(:tmpdir) { Dir.mktmpdir }

  before do
    allow(Brut).to receive(:container).and_return(test_container)
    Brut.container.store("project_root",Pathname,"",Pathname(tmpdir) / "project_root")
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe described_class::All do
    before do
      Brut.container.store(:asset_metadata_file, Pathname, "", Pathname(tmpdir + "/asset-metadata.json"))
      File.open(Brut.container.asset_metadata_file,"w") do |file|
        file.puts(JSON.generate({
          "asset_metadata" => {
            ".js"  => {},
            ".css" => {},
          },
        }))
      end
    end

    context "cleaning" do
      it "deletes the asset metadata file, then runs all three commands" do
        images = instance_double(Brut::CLI::Apps::BuildAssets::Images)
        js     = instance_double(Brut::CLI::Apps::BuildAssets::Js)
        css    = instance_double(Brut::CLI::Apps::BuildAssets::Css)

        allow(Brut::CLI::Apps::BuildAssets::Images).to receive(:new).and_return(images)
        allow(Brut::CLI::Apps::BuildAssets::Js).to     receive(:new).and_return(js)
        allow(Brut::CLI::Apps::BuildAssets::Css).to    receive(:new).and_return(css)
        allow(images).to receive(:execute)
        allow(js).to     receive(:execute)
        allow(css).to    receive(:execute)

        execution_context = test_execution_context(options: { clean: true })
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(images).to have_received(:execute).with(execution_context)
        expect(js).to     have_received(:execute).with(execution_context)
        expect(css).to    have_received(:execute).with(execution_context)
        expect(File.exist?(Brut.container.asset_metadata_file)).to eq(false) # We aren't actually running the commands, so it should not be created

      end
    end
    context "not cleaning" do
      it "runs all three commands" do
        images = instance_double(Brut::CLI::Apps::BuildAssets::Images)
        js     = instance_double(Brut::CLI::Apps::BuildAssets::Js)
        css    = instance_double(Brut::CLI::Apps::BuildAssets::Css)

        allow(Brut::CLI::Apps::BuildAssets::Images).to receive(:new).and_return(images)
        allow(Brut::CLI::Apps::BuildAssets::Js).to     receive(:new).and_return(js)
        allow(Brut::CLI::Apps::BuildAssets::Css).to    receive(:new).and_return(css)
        allow(images).to receive(:execute)
        allow(js).to     receive(:execute)
        allow(css).to    receive(:execute)

        confidence_check do
          expect(File.exist?(Brut.container.asset_metadata_file)).to eq(true)
        end

        execution_context = test_execution_context(options: { clean: false })
        result = described_class.new.execute(execution_context)

        expect(result).to eq(0)
        expect(images).to have_received(:execute).with(execution_context)
        expect(js).to     have_received(:execute).with(execution_context)
        expect(css).to    have_received(:execute).with(execution_context)
        expect(File.exist?(Brut.container.asset_metadata_file)).to eq(true)

      end
    end
  end

  describe described_class::Images do
    it "rsyncs images between the source and dest dir" do
      Brut.container.store(:images_src_dir, String,"Images source dir", "/images/src")
      Brut.container.store(:images_root_dir,String,"Images root dir",   "/images/root")
      execution_context = test_execution_context
      result = described_class.new.execute(execution_context)
      expect(result).to eq(nil)
      expect(execution_context).to have_executed([
        "rsync --archive --verbose --delete \"/images/src/\" \"/images/root\"",
      ])
    end
    it "does not --delete when --no-clean is used" do
      Brut.container.store(:images_src_dir, String,"Images source dir", "/images/src")
      Brut.container.store(:images_root_dir,String,"Images root dir",   "/images/root")
      execution_context = test_execution_context(options: { clean: false })
      result = described_class.new.execute(execution_context)
      expect(result).to eq(nil)
      expect(execution_context).to have_executed([
        "rsync --archive --verbose \"/images/src/\" \"/images/root\"",
      ])
    end
  end
  describe described_class::Css do
    let(:stderr)   { StringIO.new }

    before do
      Brut.container.store(:css_bundle_output_dir , Pathname , "" , Pathname(tmpdir + "/css-bundle-output"))
      Brut.container.store(:front_end_src_dir     , Pathname , "" , Pathname(tmpdir + "/front-end-src"))
      Brut.container.store(:tmp_dir               , Pathname , "" , Pathname(tmpdir + "/tmp"))
      Brut.container.store(:asset_metadata_file   , Pathname , "" , Pathname(tmpdir + "/asset-metadata.json"))
    end
    context "not cleaning" do
      context "esbuild fails to create the metadata file" do
        it "calls esbuild" do
          execution_context = test_execution_context(stderr:, options: { clean: false })
          result = described_class.new.execute(execution_context)
          expect(result).to eq(1)
          expect(execution_context).to have_executed([
            %r{npx esbuild .*front-end-src/css/index.css.*css-bundle-output/styles.css},
          ])
          expect(stderr.string).to match(%r{tmp/build-css-meta.json.*was not generated})
        end
      end
      context "esbuild creates the metadata file" do
        it "calls esbuild" do
          FileUtils.mkdir_p(Brut.container.css_bundle_output_dir)

          4.times do  |i|
            File.open(Brut.container.css_bundle_output_dir / "#{i}.whatever","w") do |file|
              file.puts "testing"
            end
          end
          # We need to simulate the esbuild_metafile being created since we don't want to actually
          # call esbuild
          FileUtils.mkdir_p(Brut.container.tmp_dir)
          File.open(Brut.container.tmp_dir / "build-css-meta.json","w") do |file|
            file.puts(JSON.generate({
              "outputs" => {
                "/app/public/some-path/styles-SOMEHASH.css" => { # value doesn't matter
                  "imports" => [],
                  "exports" => [],
                  "inputs" => [],
                  "bytes" => 1337,
                },
              },
            }))
          end
          execution_context = test_execution_context(stderr:, options: { clean: false })
          result = described_class.new.execute(execution_context)
          expect(result).to eq(0)
          expect(execution_context).to have_executed([
            %r{npx esbuild .*front-end-src/css/index.css.*css-bundle-output/styles.css},
          ])
          metadata = JSON.parse(File.read(Brut.container.asset_metadata_file))
          expect(metadata.dig("asset_metadata",".css")).to eq({ "/some-path/styles.css" => "/some-path/styles-SOMEHASH.css" })
          expect(Dir[Brut.container.css_bundle_output_dir / "*.*"].size).to eq(4) # we didn't write the real file, so only the original 4
        end
      end
    end
    context "cleaning" do
      it "deletes all files in the output dir, then calls esbuild" do
        # We need to simulate the esbuild_metafile being created since we don't want to actually
        # call esbuild
        FileUtils.mkdir_p(Brut.container.css_bundle_output_dir)

        4.times do  |i|
          File.open(Brut.container.css_bundle_output_dir / "#{i}.whatever","w") do |file|
            file.puts "testing"
          end
        end

        FileUtils.mkdir_p(Brut.container.tmp_dir)
        File.open(Brut.container.tmp_dir / "build-css-meta.json","w") do |file|
          file.puts(JSON.generate({
            "outputs" => {
              "/app/public/some-path/styles-SOMEHASH.css" => { # value doesn't matter
                "imports" => [],
                "exports" => [],
                "inputs" => [],
                "bytes" => 1337,
              },
            },
          }))
        end
        execution_context = test_execution_context(stderr:, options: { clean: true })
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(execution_context).to have_executed([
          %r{npx esbuild .*front-end-src/css/index.css.*css-bundle-output/styles.css},
        ])
        metadata = JSON.parse(File.read(Brut.container.asset_metadata_file))
        expect(metadata.dig("asset_metadata",".css")).to eq({ "/some-path/styles.css" => "/some-path/styles-SOMEHASH.css" })
        expect(Dir[Brut.container.css_bundle_output_dir / "*.*"]).to eq([]) # we didn't write the real file, so nothing should be here
      end
    end
  end
  describe described_class::Js do
    let(:stderr)   { StringIO.new }

    before do
      Brut.container.store(:js_bundle_output_dir , Pathname , "" , Pathname(tmpdir + "/js-bundle-output"))
      Brut.container.store(:front_end_src_dir    , Pathname , "" , Pathname(tmpdir + "/front-end-src"))
      Brut.container.store(:tmp_dir              , Pathname , "" , Pathname(tmpdir + "/tmp"))
      Brut.container.store(:asset_metadata_file  , Pathname , "" , Pathname(tmpdir + "/asset-metadata.json"))
    end
    context "not cleaning" do
      context "esbuild fails to create the metadata file" do
        it "calls esbuild" do
          execution_context = test_execution_context(stderr:, options: { clean: false })
          result = described_class.new.execute(execution_context)
          expect(result).to eq(1)
          expect(execution_context).to have_executed([
            %r{^npx esbuild .*front-end-src/js/index.js.*js-bundle-output/app.js},
          ])
          expect(stderr.string).to match(%r{tmp/build-js-meta.json.*was not generated})
        end
      end
      context "esbuild creates the metadata file" do
        it "calls esbuild" do
          FileUtils.mkdir_p(Brut.container.js_bundle_output_dir)

          4.times do  |i|
            File.open(Brut.container.js_bundle_output_dir / "#{i}.whatever","w") do |file|
              file.puts "testing"
            end
          end
          # We need to simulate the esbuild_metafile being created since we don't want to actually
          # call esbuild
          FileUtils.mkdir_p(Brut.container.tmp_dir)
          File.open(Brut.container.tmp_dir / "build-js-meta.json","w") do |file|
            file.puts(JSON.generate({
              "outputs" => {
                "/app/public/some-path/app-SOMEHASH.js" => { # the value doesn't matter
                  "imports" => [],
                  "exports" => [],
                  "inputs" => [],
                  "bytes" => 1337,
                },
              },
            }))
          end
          execution_context = test_execution_context(stderr:, options: { clean: false })
          result = described_class.new.execute(execution_context)
          expect(result).to eq(0)
          expect(execution_context).to have_executed([
            %r{^npx esbuild .*front-end-src/js/index.js.*js-bundle-output/app.js},
          ])
          metadata = JSON.parse(File.read(Brut.container.asset_metadata_file))
          expect(metadata.dig("asset_metadata",".js")).to eq({ "/some-path/app.js" => "/some-path/app-SOMEHASH.js" })
          expect(Dir[Brut.container.js_bundle_output_dir / "*.*"].size).to eq(4) # we didn't write the real file, so only the original 4
        end
        context "when overriding the file names" do
          it "calls esbuild using the overridden names from the command line" do
            FileUtils.mkdir_p(Brut.container.js_bundle_output_dir)

            4.times do  |i|
              File.open(Brut.container.js_bundle_output_dir / "#{i}.whatever","w") do |file|
                file.puts "testing"
              end
            end
            # We need to simulate the esbuild_metafile being created since we don't want to actually
            # call esbuild
            FileUtils.mkdir_p(Brut.container.tmp_dir)
            File.open(Brut.container.tmp_dir / "build-js-meta.json","w") do |file|
              file.puts(JSON.generate({
                "outputs" => {
                  "/app/public/some-path/blah-SOMEHASH.js" => { # the value doesn't matter
                    "imports" => [],
                    "exports" => [],
                    "inputs" => [],
                    "bytes" => 1337,
                  },
                },
              }))
            end
          execution_context = test_execution_context(stderr:, options: { clean: false, output_file: "blah.js", source_file: "other-source.js" })
          result = described_class.new.execute(execution_context)
            expect(result).to eq(0)
            expect(execution_context).to have_executed([
              %r{^npx esbuild .*front-end-src/js/other-source.js.*js-bundle-output/blah.js},
            ])
            metadata = JSON.parse(File.read(Brut.container.asset_metadata_file))
            expect(metadata.dig("asset_metadata",".js")).to eq({ "/some-path/blah.js" => "/some-path/blah-SOMEHASH.js" })
            expect(Dir[Brut.container.js_bundle_output_dir / "*.*"].size).to eq(4) # we didn't write the real file, so only the original 4
          end
        end
      end
    end
    context "cleaning" do
      it "deletes all files in the output dir, then calls esbuild" do
        # We need to simulate the esbuild_metafile being created since we don't want to actually
        # call esbuild
        FileUtils.mkdir_p(Brut.container.js_bundle_output_dir)

        4.times do  |i|
          File.open(Brut.container.js_bundle_output_dir / "#{i}.whatever","w") do |file|
            file.puts "testing"
          end
        end

        FileUtils.mkdir_p(Brut.container.tmp_dir)
        File.open(Brut.container.tmp_dir / "build-js-meta.json","w") do |file|
          file.puts(JSON.generate({
            "outputs" => {
              "/app/public/some-path/app-SOMEHASH.js" => { # value doesn't matter
                "imports" => [],
                "exports" => [],
                "inputs" => [],
                "bytes" => 1337,
              },
            },
          }))
        end
        execution_context = test_execution_context(stderr:, options: { clean: true })
        result = described_class.new.execute(execution_context)
        expect(result).to eq(0)
        expect(execution_context).to have_executed([
          %r{^npx esbuild .*front-end-src/js/index.js.*js-bundle-output/app.js},
        ])
        metadata = JSON.parse(File.read(Brut.container.asset_metadata_file))
        expect(metadata.dig("asset_metadata",".js")).to eq({ "/some-path/app.js" => "/some-path/app-SOMEHASH.js" })
        expect(Dir[Brut.container.js_bundle_output_dir / "*.*"]).to eq([]) # we didn't write the real file, so nothing should be here
      end
    end
  end
end
