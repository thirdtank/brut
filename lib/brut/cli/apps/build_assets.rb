require "json"
require "fileutils"

require "brut/cli"

class Brut::CLI::Apps::BuildAssets < Brut::CLI::App
  description "Build and manage code and assets destined for the browser, such as CSS, JS, or images"
  requires_project_env
  default_command :all
  configure_only!
  opts.on("--[no-]clean", "If set, any old files from previous runs are deleted. If omitted, is false in production and true otherwise")

  class All < Brut::CLI::Command
    description "Build all assets"

    def execute
      if global_options.clean?(default: global_options.env != "production")
        asset_metadata_file = Brut.container.asset_metadata_file
        out.puts "Removing #{asset_metadata_file}"
        FileUtils.rm_f(asset_metadata_file)
      end
      delegate_to_commands(Images, JS, CSS)
    end
  end

  class Images < Brut::CLI::Command
    description "Copy images to the public folder"
    detailed_description %{
This is to ensure that any images your code references will end up in the public directory, so they are served properly. This is not for managing images that may be referenced in CSS files. See the `css` command for information on that.
    }

    def execute
      src_dir  = Brut.container.images_src_dir
      dest_dir = Brut.container.images_root_dir

      command = "rsync --archive --delete --verbose #{src_dir}/ #{dest_dir}"
      system! command
    end
  end

  class Css < Brut::CLI::Command
    description "Builds a single CSS file suitable for sending to the browser"

    detailed_description %{
      This produces a hashed file in every environment, in order to keep environments consistent and reduce differences.  If your CSS file references images, fonts, or other assets via url() or other CSS functions, those files will be hashed and copied into the output directory where CSS is served.

      To ensure this happens correctly, your url() or other function must reference the file as a relative file from where your actual source CSS file is located. For example, a font named some-font.ttf would be in app/src/front_end/fonts and to reference this from app/src/front_end/css/index.css you'd use the url "../fonts/some-font.ttf"
    }

    def execute
      css_bundle          = Brut.container.css_bundle_output_dir / "styles.css"
      css_bundle_source   = Brut.container.front_end_src_dir / "css" / "index.css"
      esbuild_metafile    = Brut.container.tmp_dir / "build-css-meta.json"
      asset_metadata_file = Brut.container.asset_metadata_file

      if global_options.clean?(default: global_options.env != "production")
        out.puts "Cleaning old CSS files from #{Brut.container.css_bundle_output_dir}"
        Dir[Brut.container.css_bundle_output_dir / "*.*"].each do |file|
          if File.file?(file)
            out.puts "Deleting #{file}"
            FileUtils.rm(file)
          end
        end
      end

      command = "npx esbuild --loader:.ttf=copy --loader:.otf=copy --metafile=#{esbuild_metafile} --entry-names=[name]-[hash] --sourcemap --bundle #{css_bundle_source} --outfile=#{css_bundle}"
      out.puts "Building CSS bundle '#{css_bundle}' with '#{command}'"
      system!(command)

      if !File.exist?(esbuild_metafile)
        err.puts "'#{esbuild_metafile}' was not generated - cannot continue"
        exit 1
      end

      asset_metadata = Brut::FrontEnd::AssetMetadata.new(asset_metadata_file:,out:)
      asset_metadata.merge!(extension: ".css", esbuild_metafile:)
      asset_metadata.save!
    end
  end
  class Js < Brut::CLI::Command
    description "Builds and bundles JavaScript destined for the browser"
    opts.on("--output-file=FILE","Bundle to create that will be sent to the browser, relative to the JS public folder. Default is app.js")
    opts.on("--source-file=FILE","Entry point used to create the bundle, relative to the source JS folder. Default is index.js")

    def execute
      js_bundle           = Brut.container.js_bundle_output_dir / options.output_file(default: "app.js")
      js_bundle_source    = Brut.container.front_end_src_dir /  "js" / options.source_file(default: "index.js")
      esbuild_metafile    = Brut.container.tmp_dir / "build-js-meta.json"
      asset_metadata_file = Brut.container.asset_metadata_file

      name_with_hash_regexp = /app\/public\/(?<path>.+)\/(?<name>.+)\-(?<hash>.+)\.js/
      if global_options.clean?(default: global_options.env != "production")
        out.puts "Cleaning old JS files from #{Brut.container.js_bundle_output_dir}"
        Dir[Brut.container.js_bundle_output_dir / "*.*"].each do |file|
          if File.file?(file)
            out.puts "Deleting #{file}"
            FileUtils.rm(file)
          end
        end
      end

      command = "npx esbuild --metafile=#{esbuild_metafile} --entry-names=[name]-[hash] --sourcemap --bundle #{js_bundle_source} --outfile=#{js_bundle}"
      env_for_command = {
        "NODE_PATH" => (Brut.container.project_root / "lib").to_s, # Not needed once Brut is properly bundled
      }
      out.puts "Building JS bundle '#{js_bundle}' with '#{command}'"
      system!(env_for_command,command)

      if !File.exist?(esbuild_metafile)
        err.puts "'#{esbuild_metafile}' was not generated - cannot continue"
        exit 1
      end

      asset_metadata = Brut::FrontEnd::AssetMetadata.new(asset_metadata_file:,out:)
      asset_metadata.merge!(extension: ".js", esbuild_metafile:)
      asset_metadata.save!
    end

  end

end
