class Brut::Instrumentation::HTTPEvent < Brut::Instrumentation::Event
  def initialize(http_method:,name:,path:,details:{})
    super(category: "http", subcategory: name, name: path, details: details.merge(http_method:http_method))
  end
end
