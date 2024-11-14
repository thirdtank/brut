module Brut::SpecSupport::FlashSupport
  def empty_flash = Brut.container.flash_class.new

  def flash_from(hash)
    Brut.container.flash_class.from_h(messages: hash)
  end
end
