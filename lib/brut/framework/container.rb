require "fileutils"

module Brut
  def self.container(&block)
    @container ||= Brut::Framework::Container.new
    if !block.nil?
      block.(@container)
    end
    @container
  end
end

# This is a basic container for shared context, configuration,
# and objects. This allows easily sharing cross-cutting information
# such as project root, environment, and other objects.
#
# This can be used to store configuration values, re-usable objects,
# or anything else that is needed in the app.  Values are fetched lazily
# and can depend on other values in this container.
#
# There is no namespacing/hierarchy.
class Brut::Framework::Container
  def initialize
    @container = {}
  end

  # Store a named value for later.
  #
  # name:: The name of the value. This should be a string that is a valid Ruby identifier.
  # type:: Description of the type that the value should conform to. if this value is "boolean" or :boolean, then
  #        the value will be coerced into `true` or `false`. Otherwise, this serves as documentation for now.
  # description:: Documentation as to what this value is for.
  # value:: if given, this is the value to use.
  # block:: If value is omitted, block will be evaluated the first time the value is
  #         fetched and is expected to return the value to use for all subsequent
  #         requests.
  #
  #         The block can receive parameters and those parameters names must
  #         match other values stored in this container.  Those values are passed in.
  #
  #         For example, if you have the value `project_root`, you can then set another
  #         value called `tmp_dir` that uses `project_root` like so:
  #
  #         ```
  #         container.store("tmp_dir") { |project_root| project_root / "tmp" }
  #         ```
  def store(name,type,description,value=:use_block,allow_app_override: false,allow_nil: false,&block)
    # TODO: Check that value / block is used properly
    name = name.to_s
    if type == "boolean"
      type = :boolean
    end
    if type == :boolean
      if name !~ /\?$/
        raise ArgumentError, "#{name} is a boolean so must end with a question mark"
      end
    end
    self.validate_name!(name:,type:,allow_app_override:)
    if value == :use_block
      derive_with = block
      @container[name] = { value: nil, derive_with: derive_with }
    else
      if type == :boolean
        value = !!value
      end
      @container[name] = { value: value }
    end
    @container[name][:description]        = description
    @container[name][:type]               = type
    @container[name][:allow_app_override] = allow_app_override
    @container[name][:allow_nil]          = allow_nil
    self
  end

  def override(name,value=:use_block,&block)
    name = name.to_s
    if !@container[name]
      raise ArgumentError,"#{name} has not been specified so you cannot override it"
    end
    if !@container[name][:allow_app_override]
      raise ArgumentError,"#{name} does not allow the app to override it"
    end
    if value == :use_block
      @container[name] = { value: nil, derive_with: block }
    else
      @container[name] = { value: value }
    end
  end

  # Store a value that represents a path that must exist. The value will
  # be assumed to be of type Pathname
  def store_required_path(name,description,value=:use_block,&block)
    self.store(name,Pathname,description,value,&block)
    @container[name][:required_path] = true
    self
  end

  # Store a value that represents a path that can be created if
  # it does not exist. The path won't be created until the value is 
  # accessed the first time. The value will
  # be assumed to be of type Pathname
  def store_ensured_path(name,description,value=:use_block,&block)
    self.store(name,Pathname,description,value,&block)
    @container[name][:ensured_path] = true
    self
  end

  # Fetch a value by using its name as a method to instances of this class.
  def method_missing(sym,*args,&block)
    if args.length == 0 && block.nil? && self.respond_to_missing?(sym)
      fetch_value(sym.to_s)
    else
      super.method_missing(sym,*args,&block)
    end
  end

  # Implemented to go along with method_missing
  def respond_to_missing?(name,include_private=false)
    @container.key?(name.to_s)
  end


  # Fetch a value given a name.
  def fetch(name)
    fetch_value(name.to_s)
  end

private

  def fetch_value(name)
    # TODO: Provide a cleanr impl and better error checking if things go wrong
    x = @container.fetch(name)

    value = x[:value]

    if !value.nil? || (x[:allow_nil] && value.nil?)
      handle_path_values(name,x)
      return value
    end

    deriver = x[:derive_with]
    if deriver.nil?
      raise "Something is seriously wrong. '#{name}' was stored in container without a derive_with value"
    end

    parameters = deriver.parameters(lambda: true)
    args = parameters.map { |param_description| param_description[1] }.map { |name_of_dependent_object| self.send(name_of_dependent_object) }
    value = deriver.(*args)
    if x[:type] == :boolean
      value = !!value
    end
    x[:value] = value
    if x[:value].nil?
      if !x[:allow_nil]
        raise "Something is wrong: #{name} had no value"
      end
    end
    handle_path_values(name,x)
    x[:value]
  end

  def handle_path_values(name,contained_value)
    value = contained_value[:value]
    if contained_value[:required_path] && !Dir.exist?(value)
      raise "For value '#{name}', the directory is represents must exist, but does not: '#{value}'"
    end
    if contained_value[:ensured_path]
      FileUtils.mkdir_p value
    end
  end

  PATHNAME_NAME_REGEXP = /_(dir|file)$/

  def validate_name!(name:,type:,allow_app_override:)
    if @container.key?(name)
      if allow_app_override
        raise ArgumentError.new("Name '#{name}' has already been specified - to override it, use Brut.container.override")
      else
        raise ArgumentError.new("Name '#{name}' has already been specified - you cannot override it")
      end
    end
    if type.to_s == "Pathname"
      if name != "project_root"
        if !name.match(PATHNAME_NAME_REGEXP)
          raise ArgumentError.new("Name '#{name}' is a Pathname, and must end in '_dir' or '_file'")
        end
      end
    end
  end
end
