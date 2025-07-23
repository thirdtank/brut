class MKBrut::Ops::InsertRoute < MKBrut::Ops::PrismParsingOp
  def initialize(project_root:, code:)
    @file = project_root / "app" / "src" / "app.rb"
    @code = code
  end

  def call
    if dry_run?
      puts "Would insert route:\n#{@code}\ninto #{@file}"
      return
    end
    app_class_node = find_class(class_name: "App")

    routes_block = find_routes_block(app_class_node)

    if !routes_block
      raise "'App' in '#{@file}' did not have a routes block, so we cannot insert a new route"
    end

    end_offset = routes_block.block.location.end_offset
    indented_line = "  #{@code}\n  "
    new_source = @source.dup.insert(end_offset - 3, indented_line)

    File.open(@file, "w") do |file|
      file.puts new_source
    end
  end

  def find_routes_block(class_node)
    statements = case class_node.body 
                 when Prism::StatementsNode
                   class_node.body.body
                 when nil
                   []
                 else
                   [class_node.body]
                 end

    statements.detect do |statement|
      if statement.is_a?(Prism::CallNode)
        if statement.name == :routes
          statement.block
        else
          false
        end
      else
        false
      end
    end
  end
end

