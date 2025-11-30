# Namespace for all data models.  This makes it easy
# to avoid the conflation of database table models from
# domain models.
module DB
  # Execute the code in the block in a database transaction.
  # This calls `Sequel::Model.db.transaction`, which is ultimately
  # `Sequel::Database#transaction`. Please review that documentation as well
  # as the documentation of your databnase so you understand
  # how transactions work.
  #
  # @see https://rubydoc.info/gems/sequel/5.93.0/Sequel/Database#transaction-instance_method
  def self.transaction(opts=:use_default,&block)
    if opts == :use_default
      opts = Sequel::Database::OPTS
    end
    Sequel::Model.db.transaction(opts,&block)
  end
end

