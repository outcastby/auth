defmodule OAuth.Authorize do
  require IEx

  def call(
        %{provider: provider} = args,
        %{repo: repo, schemas: %{user: user_schema, auth: auth_schema}, required_fields: required_fields} = params
      ) do
    uid = OAuth.GetUserUniqKey.call(args)

    user_assoc = Ext.Ecto.Schema.get_schema_assoc(auth_schema, user_schema)

    case auth_schema
         |> repo.get_by(%{provider: provider, uid: uid})
         |> repo.preload(user_assoc) do
      nil ->
        if Application.get_env(Mix.Project.config()[:app], :oauth)[:close_sign_up],
          do: {:error, :sign_up_closed},
          else: OAuth.SignUp.call(args, uid, params)

      authorization ->
        OAuth.SignIn.call(Ext.Utils.Base.get_in(authorization, [user_assoc]), authorization, required_fields)
    end
  end
end
