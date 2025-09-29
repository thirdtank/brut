require "fileutils"

module Brut
  # Provides access to the singelton container that contains all of Brut's current configuration.
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
#
# In general, you should not create instances of this class, but you may
# need to access it via {Brut.container} in order to obtain
# configuration values or set your own.
class Brut::Framework::Container
  def initialize
    @container = {}
  end

  # Store a named value for later.  You can use this to store static values, or dynamic values that require the values of other stored
  # values.
  #
  # @param [String] name The name of the value. This should be a string that is a valid Ruby identifier. If `type` is a boolean, this
  #                      parameter must end in a question mark.
  # @param [String] type Description of the type that the value should conform to. if this value is "boolean" or :boolean, then
  #                      the value will be coerced into `true` or `false`. Otherwise, this serves as only documentation for now.
  # @param [String] description Documentation as to what this value is for.
  # @param [Object] value if given, this is the value to use. If the value you want is dynamically determined, or you want to create
  #                       it lazily, pass a block.
  # @param [true|false] allow_app_override if true, the app may override this value. Default is false, which means the app cannot.
  #                                        This is mostly useful for Brut internals to ensure the app doesnt' wreak havoc 
  #                                        on things it should not mess with.
  # @param [true|false] allow_nil if true, this value may be nil and if `allow_app_override` is true, the app can override the value
  #                               to be `nil`.  The default is false, which means `nil` is not allowed. Generally, you don't want
  #                               `nil`.  `nil` is no good for nobody.
  # @yield [*any] Yields any existing configuration values to the block as *positional parameters*.
  #               The names of the parameters must match the name of another configuration value.
  # @yieldreturn [Object] the value to use for this configuration option.  This is memoized, so the block will not be called again.
  #
  # @example Storing a static value
  #     container.store("num_retries",Integer,"Number of times to retry",10)
  #
  # @example Storing a dynamic value based on another one
  #     container.store("num_retries",Integer,"Number of times to retry",10)
  #     container.store("max_retry_ms",Integer,"Number of times to retry") { |num_retries|
  #       num_retries * 100
  #     }
  #
  # @see #store_required_path
  # @see #store_ensured_path
  #
  # @raise [ArgumentError] if the name has already been specified, if this is a boolean and the name doesn't
  #                        end in a question mark, or if this a `Pathname` and the name does not end in `_dir`
  #                        or `_file`.
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
      @container[name] = { derive_with: derive_with }
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

  # Called by your app to override an existing value.  The value must be overridable (see {#store}).  Generally, you should call this
  # in the initializer of your {Brut::Framework::App} subclass.  Calling this after the fact may not have the effect you want.
  #
  # @param [String|Symbol] name name of the value to override. Will be coerced to a String. This name must have been previously
  #                             configured.
  # @param [Object] value if given, this is the value to use. If omitted, the block is called
  #
  # @yield [*any] Yields any existing configuration values to the block as *positional parameters*.
  #               The names of the parameters must match the name of another configuration value.
  # @yieldreturn [Object] the value to use for this configuration option.  This is memoized, so the block will not be called again.
  def override(name,value=:use_block,&block)
    name = name.to_s
    if !@container[name]
      raise ArgumentError,"#{name} has not been specified so you cannot override it"
    end
    if !@container[name][:allow_app_override]
      raise ArgumentError,"#{name} does not allow the app to override it"
    end
    if value == :use_block
      @container[name][:derive_with] = block
      @container[name].delete(:value)
    else
      @container[name][:value] = value
      @container[name].delete(:derive_with)
    end
  end

  # Store a value that represents a path that must exist. The value will
  # be assumed to be a `Pathname` and the `name` must end in `_dir` or `_file`.
  # Note that the value's existence is not checked until it is requested. When it is,
  # an exception will be raised if it does not exist.
  #
  # @param [Symbol|String] name of this value. Must end in `_dir` or `_file`.
  # @param description [String] description documentation of what this value is for
  # @param [Object] value if given, this is the value to use. If omitted, the block is called
  #
  # @yield [*any] Yields any existing configuration values to the block as *positional parameters*.
  #               The names of the parameters must match the name of another configuration value.
  # @yieldreturn [Object] the value to use for this configuration option.  This is memoized, so the block will not be called again.
  def store_required_path(name,description,value=:use_block,&block)
    self.store(name,Pathname,description,value,&block)
    @container[name][:required_path] = true
    self
  end

  # Store a value that represents a path that will be created if it doesn't exist.
  # The value will be assumed to be a `Pathname` and the `name` must end in `_dir` or `_file`.
  #
  # This is preferred over {#store_required_path} so that you don't have to have a bunch of `.keep` files hanging around
  # just for your version control system.  The path will be created as a directory whenever it is first accessed.
  #
  # @param [Symbol|String] name of this value. Must end in `_dir` or `_file` (though ending it in `_file` doesn't make much sense).
  # @param description [String] description documentation of what this value is for
  # @param [Object] value if given, this is the value to use. If omitted, the block is called
  #
  # @yield [*any] Yields any existing configuration values to the block as *positional parameters*.
  #               The names of the parameters must match the name of another configuration value.
  # @yieldreturn [Object] the value to use for this configuration option.  This is memoized, so the block will not be called again.
  def store_ensured_path(name,description,value=:use_block,&block)
    self.store(name,Pathname,description,value,&block)
    @container[name][:ensured_path] = true
    self
  end

  # Provides method-like access to configured values. Only configured values will respond and only
  # if the accessor method is called without parameters and without a block. See {#fetch}.
  #
  # @example
  #     Brut.container.store("num_retries",Integer,"Number of times to retry",10)
  #     Brut.container.num_retries # => 10
  def method_missing(sym,*args,&block)
    if args.length == 0 && block.nil? && self.respond_to_missing?(sym)
      fetch(sym.to_s)
    else
      super.method_missing(sym,*args,&block)
    end
  end

  # Required for good decorum when overriding {#method_missing}.
  #
  # @param [String|Symbol] name the name of a previously-configured value.
  #
  # @return [true|false] true if `name` has been configured
  def respond_to_missing?(name,include_private=false)
    @container.key?(name.to_s)
  end

  # Fetch the value given a name.  For lazily-defined values, this will call all necessary blocks needed to determine the value. Thus,
  # any number of other blocks could be called, depending on what values are needed.
  #
  # @param name [Symbol|String] the name of the value to fetch.
  #
  # @return [Object] the configured value, if it has been configured. Note that if the value was defined with `allow_nil: true`
  #                  passed to {#store}, `nil` could be returned.
  # @raise [KeyError] if `name` has not been previously stored
  # @raise [Brut::Framework::Errors::NotFound] if a path stored with {#store_required_path} does not exist
  def fetch(name)
    name = name.to_s
    # TODO: Provide a cleanr impl and better error checking if things go wrong
    x = @container.fetch(name)

    has_value = x.key?(:value)

    if has_value
      handle_path_values(name,x)
      return x[:value]
    end

    deriver = x[:derive_with]
    if deriver.nil?
      raise "Something is seriously wrong. '#{name}' was stored in container without a static value, but also without a derive_with key"
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

  def reload
    @container.each do |name, contained_value|
      if contained_value.key?(:value) && contained_value[:type].to_s == "Class"
        if contained_value.key?(:derive_with)
          contained_value.delete(:value)
        else
          klass = contained_value[:value]
          if klass
            new_klass = klass.name.split(/::/).reduce(Module) { |mod,part|
              mod.const_get(part)
            }
            contained_value[:value] = new_klass
          end
        end
      end
    end
  end
private

  def handle_path_values(name,contained_value)
    value = contained_value[:value]
    if contained_value[:required_path] && !Dir.exist?(value)
      raise Brut::Framework::Errors::NotFound.new(
        resource_name: value,
        id: name,
        contetx: "For value '#{name}', the directory is represents must exist, but does not: '#{value}'"
      )
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
