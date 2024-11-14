class Brut::Instrumentation::HTTPEvent < Brut::Instrumentation::Event
  def initialize(http_method:,name:,path:,details:{})
    super(category: "http", subcategory: http_method, name: name, details: details.merge(path:path))
  end
end
