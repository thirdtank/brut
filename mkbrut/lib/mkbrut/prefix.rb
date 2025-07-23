module MKBrut
  class Prefix
    def self.from_app_id(app_id)
      app_id = app_id.to_s
      prefix = if app_id =~ /^[^-]+[a-z]-[a-z]/
                 app_id.split("-")[0..1].map { it[0] }.join("")
               else
                 app_id[0..1]
               end
      self.new(prefix)
    end

    def initialize(identifier)
      @identifier = identifier.to_s
      if @identifier.length != 2
        raise InvalidIdentifier, "prefix '#{@identifier}' must be 2 characters"
      end
      if @identifier !~ /^[a-z]+$/
        raise InvalidIdentifier, "prefix must be only lower case ASCII letters"
      end
    end

    def to_s = @identifier
    alias to_str to_s
  end
end
