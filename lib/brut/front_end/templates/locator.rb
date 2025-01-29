# Locates a template, based on a name, configured paths, and an extension.  This class forms both an API
# for template location ({#locate}) as well as an implementation that is conventional with Brut apps.
class Brut::FrontEnd::Templates::Locator
  # Create a locator that will search the given paths and require that template
  # files have the given extension
  #
  # @param [Pathname|String|Array<Pathname|String>] paths one or more paths that will be searched for templates
  # @param [String] extension file extension, without the dot, of the name of files that are considered templates
  def initialize(paths:, extension:)
    @paths     = Array(paths).map { |path| Pathname(path) }
    @extension = extension
  end

  # Given a base name, which may or may not be nested paths, returns the path to the template
  # for this file.  There must be exactly one template that matches.
  #
  # @example
  #
  #    locator = Locator.new(
  #      paths: [
  #        Brut.container.app_src_dir / "front_end" / "components",
  #        Brut.container.app_src_dir / "front_end" / "other_components",
  #      ],
  #      extension: "html.erb"
  #    )
  #
  #    # Suppose app/src/front_end/components/foo.html.erb exists
  #    path = locator.locate("foo")
  #    # => "app/src/front_end/components/foo.html.erb"
  #
  #    # Suppose app/src/front_end/components/bar/blah.html.erb exists
  #    path = locator.locate("bar/blah")
  #    # => "app/src/front_end/components/bar/blah.html.erb"
  #
  #    # Suppose both app/src/front_end/components/bar/blah.html.erb and
  #    #              app/src/front_end/other_components/bar/blah.html.erb
  #    # both exist
  #    path = locator.locate("bar/blah")
  #    # => raises an error since there are two matches
  #
  # @param [String] base_name the base name of a file that is expected to have a template.  This is searched relative to the paths
  # provided to the constructor, so it may have nested paths
  # @return [String] path to the template for the given `base_name`
  # @raises StandardError if zero or more than one templates are found
  def locate(base_name)
    paths_to_try = @paths.map { |path|
      path / "#{base_name}.#{@extension}"
    }
    paths_found = paths_to_try.select { |path|
      path.exist?
    }
    if paths_found.empty?
      raise "Could not locate template for #{base_name}. Tried: #{paths_to_try.map(&:to_s).join(', ')}"
    end
    if paths_found.length > 1
      raise "Found more than one valid pat for #{base_name}.  You must rename your files to disambiguate them. These paths were all found: #{paths_found.map(&:to_s).join(', ')}"
    end
    return paths_found[0]
  end
end
