class MKBrut::Ops::AddMethod < MKBrut::Ops::PrismParsingOp
  def initialize(file:, class_name:, code:)
    @file        = file
    @class_name  = class_name
    @code        = code.gsub(/^\n\s*$/,"").gsub(/\n$/,"")
  end

  def call
    if dry_run?
      puts "Would add method:\n#{@code}\nto #{@class_name} in '#{@file}'"
      return
    end
    class_node = find_class(class_name: @class_name, assumed_body: false)

    insert_offset = nil
    class_body_nodes = case class_node.body
                       when Prism::StatementsNode
                         class_node.body.body
                       when nil
                         []
                       else
                         [class_node.body]
                       end
                          
    class_body_nodes.each do |node|
      if node.is_a?(Prism::CallNode) && node.name == "private"
        insert_offset = node.location.start_offset
        break
      end
    end

    if insert_offset.nil?
      # Use the final end of the class
      insert_offset = class_node.location.end_offset - 3
    end

    class_start_line = class_node.location.start_line
    class_indent = @source.lines[class_start_line - 1][/^\s*/] || ""
    method_indent = class_indent + "  "

    indented_method_code = @code.lines.map { |line| method_indent + line }.join
    insert_text = "\n" + indented_method_code + "\n"

    updated_source = @source.dup.insert(insert_offset, insert_text)
    File.write(@file, updated_source)
    updated_source
  end
end
