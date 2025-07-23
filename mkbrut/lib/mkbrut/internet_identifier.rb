module MKBrut
  class InternetIdentifier
    def initialize(name, value)
      @name = name
      @identifier = value.to_s
      validate_identifier
    end

    def to_s = @identifier
    alias to_str to_s

  private

    def validate_identifier
      if @identifier.empty?
        raise MKBrut::InvalidIdentifier, "#{@name} cannot be empty"
      end

      if @identifier.length > 63
        raise MKBrut::InvalidIdentifier, "#{@name} cannot be longer than 63 characters"
      end

      if @identifier.start_with?("-") || @identifier.end_with?("-")
        raise MKBrut::InvalidIdentifier, "#{@name} cannot start or end with a hyphen"
      end

      if @identifier.match?(/[^a-zA-Z0-9-]/)
        raise MKBrut::InvalidIdentifier, "#{@name} can only contain letters, numbers, and hyphens"
      end
    end
  end 
end
