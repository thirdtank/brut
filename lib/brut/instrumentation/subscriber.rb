class Brut::Instrumentation::Subscriber
  def self.from_proc(block)
    required_parameter_names_found   = self.instance_method(:call).parameters.map { |(type,name)| [ name, false ] }.to_h
    unexpected_parameter_names_error = {}

    block.parameters.each do |(type,name)|
      if required_parameter_names_found.key?(name)
        if type == :key || type == :keyreq
          required_parameter_names_found[name] = true
        else
          unexpected_parameter_names[name] = "Not a keyword arg"
        end
      elsif type != :key
        if type == :keyreq
          unexpected_parameter_names[name] = "keyword arg without a default value"
        else
          unexpected_parameter_names[name] = "Not a keyword arg"
        end
      end
    end
    errors = []
    if unexpected_parameter_names_error.any?
      messages = unexpected_parameter_names_error.map { |name,problem|
        "#{name} - #{problem}"
      }.join(", ")
      errors << "Unexpected parameters were required, so this cannot be used as a subscriber: #{messages}"
    end
    if required_parameter_names_found.any? { |_name,found| !found }
      messages = required_parameter_names_found.select { |_name,found| !found }.map { |name,_found| "#{name} must be a keyword argument" }.join(",")
      errors << "Required parameters were missing, so this cannot be used as a subscriber: #{messages}"
    end
    if errors.any?
      raise ArgumentError,errors.join(", ")
    end
    block
  end

  def call(event:,start:,stop:,exception:)
  end

end
