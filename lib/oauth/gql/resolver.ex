defmodule OAuth.Resolver do
  use Ext.Gql.Resolvers.Base

  def authorize(params) do
    fn args, _ ->
      case OAuth.Authorize.call(args, params) do
        {:ok, user} -> {:ok, user}
        {:error, data} -> send_errors(data)
      end
    end
  end

  def twitter_authenticate_url(%{callback_url: callback_url}, _info) do
    token = ExTwitter.request_token(callback_url)
    ExTwitter.authenticate_url(token.oauth_token)
  end

  def complete(%{
        repo: repo,
        schemas: %{user: user_schema, auth: auth_schema},
        required_fields: required_fields,
        form: form
      }) do
    fn %{entity: entity, oauth_data: oauth_data}, _info ->
      user_assoc = Ext.Ecto.Schema.get_schema_assoc(auth_schema, user_schema)

      case auth_schema |> repo.get_by(oauth_data) |> repo.preload(user_assoc) do
        nil ->
          raise("Invalid oauth_data")

        authorization ->
          user = Ext.Utils.Base.get_in(authorization, [user_assoc])

          missing_fields =
            required_fields -- (user |> Map.from_struct() |> Enum.filter(fn {_, v} -> v != nil end) |> Keyword.keys())

          form = form.changeset(entity, %{missing_fields: missing_fields})

          cond do
            form.valid? -> repo.save(user, entity)
            true -> send_errors(form)
          end
      end
    end
  end
end
