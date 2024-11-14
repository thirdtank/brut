class Brut::Instrumentation::Event
  include Brut::Framework::FussyTypeEnforcement

  attr_reader :category,
              :subcategory,
              :name,
              :details

  def initialize(category:,
                 subcategory:nil,
                 name:,
                 details:{})
    @category    = type!(category,String,"category",required: true, coerce: :to_s)
    @subcategory = type!(subcategory,String,"subcategory",required: false, coerce: :to_s)
    @name        = type!(name,String,"name",required:true,coerce: :to_s)
    @details     = type!(details,Hash,"details",required:false) || {}
  end

end
