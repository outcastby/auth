defmodule Oauth.SignUp do
  require IEx

  def call(
        %{payload: payload, provider: provider},
        uid,
        %{repo: repo, schemas: %{user: user_schema}, required_fields: required_fields} = params
      ) do
    user_details = Oauth.GetUserDetails.call(provider, payload)

    user =
      if user_details.email,
        do: repo.get_or_insert!(user_schema, %{email: user_details.email}, user_details),
        else: repo.save!(user_schema.__struct__, user_details)

    authorization = create_authorizations(user, provider, uid, params)

    Oauth.SignIn.call(user, authorization, required_fields)
  end

  defp create_authorizations(user, provider, uid, %{repo: repo, schemas: %{user: user_schema, auth: auth_schema}}) do
    user
    |> Ecto.build_assoc(Ext.Ecto.Schema.get_schema_assoc(user_schema, auth_schema), %{provider: provider, uid: uid})
    |> repo.insert!()
  end
end
