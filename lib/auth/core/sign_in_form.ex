defmodule Auth.SignInForm do
  @moduledoc false
  use Ext.BaseForm

  Ext.BaseForm.schema "" do
    field :email, :string, virtual: true, required: true
    field :password, :string, virtual: true, required: true
  end

  def changeset(form) do
    form
    |> fetch_user()
    |> validate_user()
  end

  defp fetch_user(%{changes: %{email: email, context: %{repo: repo, schema: schema}}} = form),
    do: __MODULE__.with_context(form, %{user: repo.get_by(schema, email: email)})

  defp validate_user(%{changes: %{context: %{user: nil}}} = form), do: add_error(form, :email, "invalid_email")

  defp validate_user(
         %{changes: %{password: password, context: %{user: %{encrypted_password: encrypted_password}}}} = form
       ) do
    if Bcrypt.verify_pass(password, encrypted_password),
      do: form,
      else: add_error(form, :password, "invalid_password")
  end
end
