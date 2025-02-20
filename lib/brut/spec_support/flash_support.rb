# Convienience methods for using a Flash inside tests.
module Brut::SpecSupport::FlashSupport
  # Create a normal empty flash, using the app's configured class.
  def empty_flash = Brut.container.flash_class.new

  # Create a flash using the app's configured class that contains the given hash as its values.
  #
  # @param [Hash] hash Values to include in the Flash.
  def flash_from(hash)
    Brut.container.flash_class.from_h(messages: hash)
  end
end
