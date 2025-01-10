require "bundler/gem_tasks"

require "pathname"

docs_dir = (Pathname(__FILE__).dirname / "docs").expand_path.to_s
desc "Generate YARD doc"
task :docs do
  system "bundle exec yard doc -o '#{docs_dir}' --files doc-src/architecture.md -m markdown -M rdiscount --backtrace"
end

desc "Show YARD status"
task :stats do
  system "bundle exec yard stats --list-undoc"
end

desc "Clean up droppings"
task :clean do
  FileUtils.rm_rf docs_dir, verbose: true
end

