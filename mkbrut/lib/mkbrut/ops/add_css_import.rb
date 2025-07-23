class MKBrut::Ops::AddCSSImport < MKBrut::Ops::BaseOp
  def initialize(project_root:, import:)
    @file   = project_root / "app" / "src" / "front_end" / "css" / "index.css"
    @import = import
  end

  def call
    if dry_run?
      puts "Would add import '#{@import}'; to '#{@file}'"
      return
    end

    contents = File.read(@file).split(/\n/)

    inserted_import          = false
    previous_line_was_import = false
    new_contents = []
    contents.each do |line|
      if line =~ /^\s*@import\s+["']/
        previous_line_was_import = true
        new_contents << line
      else
        if previous_line_was_import && !inserted_import
          new_contents << "@import '#{@import}';"
          inserted_import = true
        end
        previous_line_was_import = false
        new_contents << line
      end
    end
    if !inserted_import && previous_line_was_import
      new_contents << "@import \"#{@import}\";"
      inserted_import = true
    end
    if !inserted_import
      raise "Did not find any other @imports in '#{@file}' - was expecting at least one to exist"
    end
    File.open(@file, "w") do |file|
      file.puts new_contents.join("\n")
    end
  end
end
