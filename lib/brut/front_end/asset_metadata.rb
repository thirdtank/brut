# Class to provide access to the asset metadata used to serve up hashed assets. Generally, you will not interact with this class.
#
# @!visibility private
class Brut::FrontEnd::AssetMetadata

  # @param [String] asset_metadata_file to the asset metadata file
  # @param [IO] out IO on which to write messaging
  def initialize(asset_metadata_file:,out:$stdout)
    @asset_metadata_file = asset_metadata_file
    @out = out
    @asset_metadata = nil
  end

  def merge!(extension:,esbuild_metafile:)
    @out.puts "Parsing metafile '#{esbuild_metafile}'"
    esbuild_metafile = ESBuildMetafile.new(metafile:esbuild_metafile)
    metadata = esbuild_metafile.parse(extension:)
    begin
      self.load!
    rescue Errno::ENOENT
      @out.puts "'#{@asset_metadata_file}' does not exist - creating it"
      @asset_metadata = {}
    end
    existing_metadata = @asset_metadata[extension] || {}
    @asset_metadata[extension] = existing_metadata.merge(metadata)
  end

  def load!
    metadata = JSON.parse(File.read(@asset_metadata_file))
    if !metadata.key?("asset_metadata")
      raise "Asset metadata file '#{@asset_metadata_file}' is corrupted. There is no top-level 'asset_metadata' key"
    end
    @asset_metadata = metadata["asset_metadata"]
  end

  def resolve(path)
    extension = File.extname(path)
    @asset_metadata ||= {}
    if @asset_metadata[extension]
      if @asset_metadata[extension][path]
        @asset_metadata[extension][path]
      else
        raise "Asset metadata does not have a mapping for '#{path}'"
      end
    else
      raise "Asset metadata has not been set up for files with extension '#{extension}'"
    end
  end

  def save!
    @out.puts "Writing updated asset metadata file '#{@asset_metadata_file}'"
    File.open(@asset_metadata_file,"w") do |file|
      file.puts({ "asset_metadata" => @asset_metadata }.to_json)
    end
  end

  # @!visibility private
  class ESBuildMetafile
    def initialize(metafile:)
      @metafile = metafile
    end

    def parse(extension:)
      metafile_contents = JSON.parse(File.read(@metafile))

      name_with_hash_regexp = /app\/public\/(?<path>.+)\/(?<name>.+)\-(?<hash>.+)#{Regexp.escape(extension)}/
      metadata = metafile_contents["outputs"].keys.map { |key|
        match_data = key.match(name_with_hash_regexp)
        if match_data
          path = match_data[:path]
          name = match_data[:name]
          hash = match_data[:hash]

          [ "/#{path}/#{name}#{extension}", "/#{path}/#{name}-#{hash}#{extension}" ]
        else
          nil
        end
      }.compact.to_h
    end
  end

end
