require "erb"
class MKBrut::Ops::RenderTemplate < MKBrut::Ops::BaseOp

  def initialize(source, destination_root:, erb_binding:)
    @erb              = source
    @destination_file = destination_root / @erb.basename.sub_ext("")
    @erb_binding      = erb_binding
  end

  def call
    if dry_run?
      puts "Render '#{@destination_file}'"
      return
    end
    template = File.read(@erb)
    File.open(@destination_file, "w") do |file|
      file.puts ERB.new(
        template,
        trim_mode: "-"
      ).result(
        @erb_binding.instance_eval { binding }
      )
    end
  end
  def to_s = "ERB '#{@erb}' to '#{@destination_file}'"
end
