class MKBrut::Ops::AppendToFile < MKBrut::Ops::BaseOp
  def initialize(file:, content:)
    @file    = file
    @content = content
  end

  def call
    if dry_run?
      puts "Would append to #{@file}:\n#{@content}\n"
      return
    end

    contents = File.read(@file)
    File.open(@file, "w") do |file|
      file.puts contents
      file.puts "\n"
      file.puts @content
    end
  end
end
