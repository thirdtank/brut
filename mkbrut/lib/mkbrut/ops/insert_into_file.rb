class MKBrut::Ops::InsertIntoFile < MKBrut::Ops::BaseOp
  def initialize(file:, content:, before_line:)
    @file        = file
    @content     = content
    @before_line = before_line
  end

  def call

    contents = File.read(@file)
    locations = []
    new_contents = []
    contents.split("\n").each_with_index do |line, index|
      if line == @before_line
        new_contents << @content
        locations << (index + 1)
      end
      new_contents << line
    end
    if locations.empty?
      raise "Did not find line '#{@before_line}' exactly in #{@file}"
    end
    if locations.size > 1
      raise "Found exact line '#{@before_line}' #{locations.size} times in #{@file}, should be exactly once so we know where to insert"
    end

    if dry_run?
      puts "Would add to #{@file}, resulting in this content:\n#{new_contents.join("\n")}\n"
      return
    end

    File.open(@file, "w") do |file|
      file.puts new_contents.join("\n")
    end
  end
end
