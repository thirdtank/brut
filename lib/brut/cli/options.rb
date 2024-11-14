# Convienience module to put into Hash to allow options
# parsed to be a bit more accessible
class Brut::CLI::Options
  def initialize(parsed_options)
    @parsed_options = parsed_options
    @defaults = {}
  end

  def to_h = @parsed_options

  def [](key) = @parsed_options[key]
  def key?(key) = @parsed_options.key?(key)
  def set_default(sym,default_value)
    @defaults[sym] = default_value
  end

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
