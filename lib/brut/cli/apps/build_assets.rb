require "json"
require "fileutils"

require "brut/cli"

class Brut::CLI::Apps::BuildAssets < Brut::CLI::Commands::BaseCommand
  def description = "Build and manage code and assets destined for the browser, such as CSS, JS, or images"

  class BaseCommand < Brut::CLI::Commands::BaseCommand
    def bootstrap? = false
    def default_rack_env = "development"
    def opts = [
      [
        "--[no-]clean",
        "If set, any old files from previous runs are deleted. Defaults to false in production, true everywhere else.",
      ],
    ]
    def friendly_name(file)
      Pathname(file).relative_path_from(Brut.container.project_root).to_s
    end
  end

  def name = "build-assets" 

  def default_command
    @default_command ||= All.new
  end
  def bootstrap? = default_command.bootstrap?
  def default_rack_env = default_command.default_rack_env

  def run
    delegate_to_command(default_command)
  end

  def commands = [
    All.new,
    Images.new,
    Css.new,
    Js.new,
  ]


  class All < Brut::CLI::Commands::CompoundCommand
    def default_rack_env = "development"
    def description = "Build all assets"
    def bootstrap? = false

    def initialize
      super([
        Images.new,
        Css.new,
        Js.new,
      ])
    end

    def execute(execution_context)
      if execution_context.options.clean?(default: execution_context.options.env != "production")
        asset_metadata_file = Brut.container.asset_metadata_file
        execution_context.stdout.puts "Removing #{asset_metadata_file}"
        FileUtils.rm_f(asset_metadata_file)
      end
      super
    end
  end

  class Images < BaseCommand
    def description = "Copy images to the public folder"
    def detailed_description = %{
This is to ensure that any images your code references will end up in the public directory, so they are served properly. This is not for managing images that may be referenced in CSS files. See the `css` command for information on that.
    }

    def run
      src_dir  = Brut.container.images_src_dir
      dest_dir = Brut.container.images_root_dir

      puts "Syncing images from #{theme.code.render(friendly_name(src_dir.to_s))} to #{theme.code.render(friendly_name(dest_dir.to_s))}"
      rsync_args = [
        "--archive",
        "--verbose",
      ]
      if options.clean?(default: options.env != "production")
        puts "Deleting old images from #{theme.code.render(friendly_name(dest_dir.to_s))}"
        rsync_args << "--delete"
      end
      system! "rsync #{rsync_args.join(' ')} \"#{src_dir}/\" \"#{dest_dir}\""
    end
  end


  class Css < BaseCommand
    def description = "Builds a single CSS file suitable for sending to the browser"

    def detailed_description = %{
      This produces a hashed file in every environment, in order to keep environments consistent and reduce differences.  If your CSS file references images, fonts, or other assets via `url()` or other CSS functions, those files will be hashed and copied into the output directory where CSS is served.

      To ensure this happens correctly, your `url()` or other function must reference the file as a relative file from where your actual source CSS file is located. For example, a font named `some-font.ttf` would be in `app/src/front_end/fonts`. To reference this from `app/src/front_end/css/index.css` you'd use `url("../fonts/some-font.ttf")`
    }

    def run
      css_bundle          = Brut.container.css_bundle_output_dir / "styles.css"
      css_bundle_source   = Brut.container.front_end_src_dir / "css" / "index.css"
      esbuild_metafile    = Brut.container.tmp_dir / "build-css-meta.json"
      asset_metadata_file = Brut.container.asset_metadata_file

      if options.clean?(default: options.env != "production")
        puts "Cleaning old CSS files from #{theme.code.render(friendly_name(Brut.container.css_bundle_output_dir.to_s))}"
        Dir[Brut.container.css_bundle_output_dir / "*.*"].each do |file|
          if File.file?(file)
            puts theme.weak.render("  Deleting #{theme.code.render(friendly_name(file))}")
            FileUtils.rm(file)
          end
        end
      end

      # NOTE: esbuild outputs its normal messages on stderr which is fucking stupid
      command = "npx esbuild --loader:.ttf=copy --loader:.otf=copy --metafile=#{esbuild_metafile} --entry-names=[name]-[hash] --sourcemap --bundle #{css_bundle_source} --outfile=#{css_bundle} 2>&1"
      puts "Building CSS bundle '#{theme.code.render(friendly_name(css_bundle))}'"

      system!(command)

      if !File.exist?(esbuild_metafile)
        error "'#{esbuild_metafile}' was not generated"
        puts theme.error.render("esbuild did not generate the metafile we asked for (#{esbuild_metafile})")
        puts theme.error.render("This file is required to continue")
        return 1
      end

      asset_metadata = Brut::FrontEnd::AssetMetadata.new(asset_metadata_file:,logger:execution_context.logger)
      asset_metadata.merge!(extension: ".css", esbuild_metafile:)
      asset_metadata.save!
      0
    end
  end
  class Js < BaseCommand
    def description = "Builds and bundles JavaScript destined for the browser"
    def opts = super + [
      [
        "--output-file=FILE",
        "Bundle to create that will be sent to the browser, relative to the JS public folder. Default is app.js",
      ],
      [
        "--source-file=FILE",
        "Entry point used to create the bundle, relative to the source JS folder. Default is index.js",
      ],
    ]

    def run
      js_bundle           = Brut.container.js_bundle_output_dir / options.output_file(default: "app.js")
      js_bundle_source    = Brut.container.front_end_src_dir /  "js" / options.source_file(default: "index.js")
      esbuild_metafile    = Brut.container.tmp_dir / "build-js-meta.json"
      asset_metadata_file = Brut.container.asset_metadata_file

      name_with_hash_regexp = /app\/public\/(?<path>.+)\/(?<name>.+)\-(?<hash>.+)\.js/
      if options.clean?(default: options.env != "production")
        puts "Cleaning old JS files from #{friendly_name(Brut.container.js_bundle_output_dir)}"
        Dir[Brut.container.js_bundle_output_dir / "*.*"].each do |file|
          if File.file?(file)
            puts theme.weak.render("  Deleting #{theme.code.render(friendly_name(file))}")
            FileUtils.rm(file)
          end
        end
      end

      # NOTE: esbuild outputs its normal messages on stderr which is fucking stupid
      command = "npx esbuild --metafile=#{esbuild_metafile} --entry-names=[name]-[hash] --sourcemap --bundle #{js_bundle_source} --outfile=#{js_bundle} 2>&1"
      puts "Building JS bundle '#{theme.code.render(friendly_name(js_bundle))}'"
      system!(command)

      if !File.exist?(esbuild_metafile)
        error "'#{esbuild_metafile}' was not generated - cannot continue"
        return 1
      end

      asset_metadata = Brut::FrontEnd::AssetMetadata.new(asset_metadata_file:,logger: execution_context.logger)
      asset_metadata.merge!(extension: ".js", esbuild_metafile:)
      asset_metadata.save!
      0
    end

  end

end
