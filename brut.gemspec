lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "brut/version"

Gem::Specification.new do |spec|
  spec.name          = "brut"
  spec.version       = Brut::VERSION
  spec.authors       = ["David Bryant Copeland"]
  spec.email         = ["davec@thirdtank.com"]

  spec.summary       = %q{NOT YET RELEASED - Web Framework Built around Ruby, Web Standards, Simplicity, and Object-Orientation}
  spec.description   = %q{NOT YET RELEASED - An opinionated web framework build on web standards}
  spec.homepage      = "https://naildrivin5.com"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://naildrivin5.com"
    spec.metadata["changelog_uri"] = "https://naildrivin5.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "irb"
  spec.add_runtime_dependency "ostruct" # squelch some warning - this is not used
  spec.add_runtime_dependency "concurrent-ruby"
  spec.add_runtime_dependency "i18n"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency "phlex"
  spec.add_runtime_dependency "prism"
  spec.add_runtime_dependency "rack-protection"
  spec.add_runtime_dependency "rackup"
  spec.add_runtime_dependency "semantic_logger"
  spec.add_runtime_dependency "sequel"
  spec.add_runtime_dependency "sinatra"
  spec.add_runtime_dependency "tzinfo"
  spec.add_runtime_dependency "tzinfo-data"
  spec.add_runtime_dependency "zeitwerk"
  spec.add_runtime_dependency "opentelemetry-sdk"
  spec.add_runtime_dependency "opentelemetry-exporter-otlp"

  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "rdiscount"
  spec.add_development_dependency "rdoc"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "faker"
end
