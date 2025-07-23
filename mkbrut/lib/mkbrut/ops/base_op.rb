class MKBrut::Ops::BaseOp
  @dry_run = false

  def self.dry_run=(value)
    MKBrut::Ops::BaseOp.instance_variable_set(:@dry_run, value)
  end

  def self.dry_run? = !!MKBrut::Ops::BaseOp.instance_variable_get(:@dry_run)
  def dry_run? = self.class.dry_run?

  def call = raise "Subclass must implement"

  def self.fileutils_args
    if self.dry_run?
      { noop: true, verbose: true }
    else
      {}
    end
  end
  def fileutils_args = self.class.fileutils_args
end
