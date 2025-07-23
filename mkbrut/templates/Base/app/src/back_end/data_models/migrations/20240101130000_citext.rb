Sequel.migration do
  up do
    run %{CREATE EXTENSION IF NOT EXISTS citext}
  end
end

