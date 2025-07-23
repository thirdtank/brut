class MKBrut::Ops::AddI18nMessage < MKBrut::Ops::PrismParsingOp
  def initialize(project_root:, hash:)
    @file = project_root / "app" / "config" / "i18n" / "en" / "2_app.rb"
    @hash = hash
  end

  def call
    if dry_run?
      puts "Would merge:\n#{@hash}\ninto #{@file}"
      return
    end
    parse_file!

    hash_node = @tree.value.statements.body.detect { it.is_a?(Prism::HashNode) }
    if !hash_node
      raise "'#{@file}' did not have a hash node, so we cannot insert a new i18n message"
    end

    # eval the source to get a real hash of the contents
    start_offset  = hash_node.location.start_offset
    end_offset    = hash_node.location.end_offset
    original_code = @source[start_offset...end_offset]
    original_hash = eval(original_code, binding, @file.to_s)

    new_hash = deep_merge(original_hash,@hash)

    formatted_hash = format_hash(new_hash)

    new_source = @source.dup
    new_source[start_offset...end_offset] = formatted_hash

    File.open(@file, "w") do |file|
      file.puts new_source
    end
  end

private

  def deep_merge(a, b)
    a.merge(b) do |_key, old_val, new_val|
      if old_val.is_a?(Hash) && new_val.is_a?(Hash) 
        deep_merge(old_val, new_val)
      else
        new_val
      end
    end
  end

  # NASTY, but not currently sure a better what do it.
  def format_hash(hash, trailing_comma = "", indent = "")
    string = "{\n"
    hash.each do |key, value|
      key_code = if key.kind_of?(Symbol)
                   if key =~ /^[A-Za-z_][A-Za-z0-9_]*$/
                     "#{key}:"
                   else
                     "'#{key}':"
                   end
      else
        "#{key} =>"
      end
      value_code = case value
                   when String
                     then "\"#{value}\",\n"
                   when Hash
                     format_hash(value, ",", indent + "  ")
                   end
      string << "#{indent}  #{key_code} #{value_code}"
    end
    string << "#{indent}}#{trailing_comma}\n"
    string
  end
end

