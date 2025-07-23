module MKBrut
  class AppName
    def initialize(value)
      identifier = value.to_s
      if identifier.empty?
        raise MKBrut::InvalidIdentifier, "app-name is required"
      end

      if identifier.length > 63
        raise MKBrut::InvalidIdentifier, "app-name cannot be longer than 63 characters"
      end

      if identifier.start_with?("-") || identifier.end_with?("-")
        raise MKBrut::InvalidIdentifier, "app-name cannot start or end with a hyphen"
      end

      if identifier.match?(/[^a-zA-Z\-_]/)
        raise MKBrut::InvalidIdentifier, "app-name can only contain letters, hyphens, and underscores"
      end
      if identifier.match?(/__/) || identifier.match?(/--/)
        raise MKBrut::InvalidIdentifier, "app-name can not have repeating underscores or hyphens"
      end
      @identifier = identifier.to_s.gsub(/_/,"-")
    end

    def to_s = @identifier
    alias to_str to_s
  end
end
