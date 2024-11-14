# A temple "engine" that can be used to parse ERB and generate HTML
# in just the way we need.
class Brut::FrontEnd::Templates::ERBEngine < Temple::Engine
  # Parse the ERB into sexps
  use Brut::FrontEnd::Templates::ERBParser

  # Handle block syntax used in a <%= 
  use Brut::FrontEnd::Templates::BlockFilter

  # Trim whitespace like ERB does
  use Temple::ERB::Trimming

  # Escape strings only if they are not HTMLSafeString
  use Brut::FrontEnd::Templates::EscapableFilter
  # This filter actually runs the Ruby code
  use Temple::Filters::StaticAnalyzer
  # Flattens nested :multi expressions which I'm not sure is needed, but
  # have cargo-culted from hanami
  use Temple::Filters::MultiFlattener
  # merges sequential :static, which again, not sure is needed, but
  # have cargo-culted from hanami
  use Temple::Filters::StaticMerger

  # This generates everything into a string
  use Temple::Generators::ArrayBuffer
end
