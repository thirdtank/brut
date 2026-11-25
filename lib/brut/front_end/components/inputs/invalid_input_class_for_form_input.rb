class Brut::FrontEnd::Components::Inputs::InvalidInputClassForFormInput < ArgumentError
  def initialize(component:, required_class:, received_class:)
    super("#{component.class} can only be used with a `#{required_class}`, not #{received_class}")
  end
end
