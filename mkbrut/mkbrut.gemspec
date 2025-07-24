lib = File.expand_path("../lib", __FILE__)
if !$LOAD_PATH.include?(lib)
  $LOAD_PATH.unshift(lib)
end
require "mkbrut/version"
Gem::Specification.new do |spec|
  spec.name          = "mkbrut"
  spec.version       = MKBrut::VERSION
  spec.authors       = ["Dave Copeland"]
  spec.email         = ["davec@naildrivin5.com"]

  spec.summary       = "Create a new Brut App"
  spec.description   = "mkbrut is how you go from zero to having a Brut app where you can start working."
  spec.homepage      = "https://brutrb.com"
  spec.bindir        = "exe"

  spec.files = Dir.glob("lib/**/*.rb") +   # Gem source code
               Dir.glob(                   # Templates used to create a new Brut app
                 "templates/**/*",
                 flags: File::FNM_DOTMATCH
               ).reject {
                 it =~ /\/\.{1,2}$/ # Pesky dotfile
               }.reject {
                 it =~ /\.DS_Store$/ # FML
               } +                          
               [
                 "exe/mkbrut",             # executable
               ]

  spec.executables   = ["mkbrut"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
end 
