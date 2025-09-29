class MKBrut::Ops::InsertCodeInMethod < MKBrut::Ops::PrismParsingOp
  def initialize(file:,
                 class_name:,
                 method_name:,
                 class_method: false,
                 code:,
                 ignore_if_file_not_found: false,
                 where: :end)
    @file                     = file
    @class_name               = class_name
    @method_name              = method_name.to_sym
    @class_method             = class_method
    @code                     = code
    @ignore_if_file_not_found = ignore_if_file_not_found
    @where                    = where
  end

  def call
    if !@file.exist? && @ignore_if_file_not_found
      return
    end
    method_node = find_method(class_name: @class_name, method_name: @method_name, class_method: @class_method)

    insertion_point = if @where == :start
                        insertion_point_for_code_at_start_of_method(method_node: method_node)
                      else
                        insertion_point_for_code_at_end_of_method(method_node: method_node)
                      end
    indented_code = indent_code_for_method(method_node: method_node)

    new_source = @source.dup.insert(insertion_point, indented_code)
    File.write(@file, new_source)
  end

private

  def indent_code_for_method(method_node:)

    method_start_line = method_node.location.start_line
    spaces_before_def = @source.lines[method_start_line - 1][/^\s*/] || ""
    spaces_for_code_in_method = spaces_before_def + "  "

    post_indent = if @where == :start
                    "\n#{spaces_before_def}"
                  else
                    ""
                  end


    "\n" + 
      @code.split(/\n/).map { |line|
        spaces_for_code_in_method + line
      }.join("\n") + post_indent
  end

  # XXX: This does not work with non-ASCII strings
  def insertion_point_for_code_at_end_of_method(method_node:)
    line_number_of_method_end = method_node.location.end_line - 1
    length_of_method_end      = @source.lines[line_number_of_method_end].length

    method_node.location.end_offset - length_of_method_end
  end

  def insertion_point_for_code_at_start_of_method(method_node:)
    line_number_of_method_start = method_node.location.start_line - 1
    length_of_method_start      = @source.lines[line_number_of_method_start].length

    method_node.location.start_offset + length_of_method_start
  end
end
