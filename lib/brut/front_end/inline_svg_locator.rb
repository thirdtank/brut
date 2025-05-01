class Brut::FrontEnd::InlineSvgLocator
  def initialize(paths:)
    @paths = Array(paths).map { |path| Pathname(path) }
  end

  def locate(base_name)
    paths_to_try = @paths.map { |path|
      path / "#{base_name}.svg"
    }
    paths_found = paths_to_try.select { |path|
      path.exist?
    }
    if paths_found.empty?
      raise "Could not locate SVG for #{base_name}. Tried: #{paths_to_try.map(&:to_s).join(', ')}"
    end
    if paths_found.length > 1
      raise "Found more than one valid path for #{base_name}.  You must rename your files to disambiguate them. These paths were all found: #{paths_found.map(&:to_s).join(', ')}"
    end
    return paths_found[0]
  end
end
