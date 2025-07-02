# Wraps parsed command line options to provide a method-like interface instead of simple `Hash` acceess.  Also allows specifying default values when an option wasn't given on the command line, as well as boolean coercion for switches.  Allows accessing options via snake_case in code, even if specified via kebab-case on the command line.
class Brut::CLI::Options
  def initialize(parsed_options)
    @parsed_options = parsed_options
    @defaults = {}
  end

  # Returns the parsed options as a `Hash`
  # @return [Hash]
  def to_h = @parsed_options

  # Access an options value directly.
  # @param [String] key the key to use. This must be the exact name you used when calling `opts.on` or when creating the `OptionParser` for your app or command. Generally, use the {#method_missing}-provided version instead of this.
  def [](key) = @parsed_options[key]

  def []=(key,value)
    @parsed_options[key] = value
  end
  # Check if `key` was provided on the command line.
  # @param [String] key the key to use. This must be the exact name you used when calling `opts.on` or when creating the `OptionParser` for your app or command.
  def key?(key) = @parsed_options.key?(key)

  # Set a default value for an option when {#method_missing} is used to access it and that flag or switch was not used on the command
  # line.
  # @param [Symbol] sym the symbol of the option, either in kebab-case or snake_case.
  # @param [Object] default_value the value to return if that option was not used on the command line
  def set_default(sym,default_value)
    @defaults[sym] = default_value
  end

  # Dynamically creates methods for each command-line option.  Note that this doesn't know what options could've been provided, so it
  # will respond to any method that either takes no arguments or where the only argument is `default:`.
  #
  # @param [Symbol] sym kebab or snake case value of the option. A question mark should be used if the option is to be coerced to a booealn.
  # @param [Array|Hash] args if the first arg is a Hash with the key `default:`, this value will be used if `sym` has no value
  #
  # @return [true|false|nil|Object] the value of the option used on the command line, or the default used in `default:`, or the
  # preconfigured default, or `nil`.  If `sym` ended in a question mark, true or false will be returned (never nil).
  #
  # @example
  #
  #    # Suppose the user provided `--log-level=debug --dry-run` on the command line
  #    options.log_level               # => "debug"
  #    options.verbose                 # => nil
  #    options.verbose(default: "yes") # => "yes"
  #    options.dry_run?                # => true
  #    options.slow?                   # => false
  def method_missing(sym,*args,&block)
    boolean = false
    if sym.to_s =~ /\?$/
      sym = sym.to_s[0..-2].to_sym
      boolean = true
    end

    sym_underscore = sym.to_s.gsub(/\-/,"_").to_sym
    sym_dash       = sym.to_s.gsub(/_/,"-").to_sym

    value = if self.key?(sym_underscore)
              self[sym_underscore]
            elsif self.key?(sym_dash)
              self[sym_dash]
            elsif args[0].kind_of?(Hash) && args[0].key?(:default)
              return args[0][:default]
            elsif @defaults.key?(sym_underscore)
              @defaults[sym_underscore]
            elsif @defaults.key?(sym_dash)
              @defaults[sym_dash]
            else
              nil
            end
    if boolean
      !!value
    else
      value
    end
  end
end
