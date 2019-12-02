defmodule TestUser do
  use Ecto.Schema

  schema "test_users" do
    field(:email, :string)
    field(:refresh_token, :string)
    field(:encrypted_password, :string)
    field(:restore_hash, :string)
    field(:restore_expire, :utc_datetime_usec)
    has_many(:test_authorizations, TestAuthorization)
  end
end
