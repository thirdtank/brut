require "bundler/gem_tasks"

require "pathname"

docs_dir = (Pathname(__FILE__).dirname / "docs").expand_path.to_s
plugins_dir = (Pathname(__FILE__).dirname / "yard-plugins" ).expand_path.relative_path_from(
  Pathname(__FILE__).dirname
)
desc "Generate YARD doc"
task :docs do
  plugins_flags = Dir["#{plugins_dir}/*.rb"].map { |f| 
    "-e #{f}"
  }.join(" ")
  system "bundle exec yard doc #{plugins_flags} -o '#{docs_dir}' -m markdown -M rdiscount --backtrace"
end

desc "Show YARD status"
task :stats do
  system "bundle exec yard stats --list-undoc"
end

desc "Clean up droppings"
task :clean do
  FileUtils.rm_rf docs_dir, verbose: true
end
