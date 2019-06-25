defmodule Oauth.Authorize do
  require IEx

  def call(
        %{provider: provider} = args,
        %{repo: repo, schemas: %{user: user_schema, auth: auth_schema}, required_fields: required_fields} = params
      ) do
    uid = Oauth.GetUserUniqKey.call(args)

    user_assoc = Ext.Ecto.Schema.get_schema_assoc(auth_schema, user_schema)

    case auth_schema
         |> repo.get_by(%{provider: provider, uid: uid})
         |> repo.preload(user_assoc) do
      nil ->
        Oauth.SignUp.call(args, uid, params)

      authorization ->
        Oauth.SignIn.call(Ext.Utils.Base.get_in(authorization, [user_assoc]), authorization, required_fields)
    end
  end
end
