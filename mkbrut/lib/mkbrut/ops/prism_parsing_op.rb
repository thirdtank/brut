require "prism"
class MKBrut::Ops::PrismParsingOp < MKBrut::Ops::BaseOp
  def initialize(file:)
    @file = file
  end

  class ClassNotInSource < StandardError
    def initialize(file:, class_name:)
      super("Could not find the class '#{class_name}' inside '#{file}'")
    end
  end

  class MethodNotInClass < StandardError
    def initialize(file:, class_name:, method_name:)
      super("Could not find the method '#{method_name}' in class '#{class_name}' inside '#{file}'")
    end
  end

  class SourceNotParseable < StandardError
    def initialize(tree_errors:, file:)
      error_message = tree_errors.map { |error|
        "#{error.message} (line #{error.location.start_line}, column #{error.location.start_column})"
      }.join(", ")
      super("Failed to parse file '#{file}': #{error_message}")
    end
  end

private

  def parse_file!
    source = File.read(@file)
    tree = Prism.parse(source)

    if !tree.success?
      raise SourceNotParseable.new(tree_errors: tree.errors, file: @file)
    end
    @tree = tree
    @source = source
  end

  def find_class(class_name:, assumed_body: true)
    if !@tree
      parse_file!
    end
    class_node = @tree.value.statements.body.detect { |node|
      node.is_a?(Prism::ClassNode) && node.constant_path.slice == class_name
    }

    if !class_node
      raise ClassNotInSource.new(file: @file, class_name: class_name)
    end

    if !class_node.body.respond_to?(:body) && assumed_body
      raise "The class '#{class_name}' in '#{file}' does not have any methods"
    end
    class_node
  end

  def find_method(class_name:, method_name:)
    class_node = find_class(class_name:)
    method_node = class_node.body.body.detect { |node|
      node.is_a?(Prism::DefNode) && node.name == @method_name
    }

    if !method_node
      raise MethodNotInClass.new(file: @file, class_name: class_name, method_name: @method_name)
    end
    method_node
  end
end
