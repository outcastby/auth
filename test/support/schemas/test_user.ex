defmodule TestUser do
  use Ecto.Schema

  schema "test_users" do
    field(:email, :string)
    has_many(:test_authorizations, TestAuthorization)
  end
end
