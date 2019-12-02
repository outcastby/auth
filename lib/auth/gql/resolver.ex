defmodule Auth.Resolver do
  use Ext.GQL.Resolvers.Base
  import Ext.Utils.Map

  def sign_in(%{repo: repo} = params) do
    fn args, _ ->
      form = %{changes: %{context: %{user: user}}} = Auth.SignInForm.call(args, params)

      if form.valid?, do: {:ok, Auth.GenerateJWTData.call(user, repo)}, else: send_errors(form)
    end
  end

  def sign_up(%{repo: repo, schema: schema} = params) do
    fn args, info ->
      if Auth.CheckCloseSignUp.call(schema) do
        send_errors("sign_up_closed")
      else
        case Ext.GQL.Resolvers.Base.create(params).(args, info) do
          {:ok, user} -> {:ok, Auth.GenerateJWTData.call(user, repo)}
          error -> error
        end
      end
    end
  end

  def forgot_password(%{repo: repo, send_caller: send_caller} = params) do
    fn %{restore_url: restore_url} = args, _ ->
      form = %{changes: %{context: %{user: user}}} = Auth.ForgotPasswordForm.call(args, params)

      if form.valid? do
        user = Auth.AddRestorePasswordData.call(user, repo)
        send_caller.(user, restore_url)
        {:ok, "ok"}
      else
        send_errors(form)
      end
    end
  end

  def restore_password(%{repo: repo} = params) do
    fn %{entity: entity}, _ ->
      restore_form = %{changes: %{context: %{user: user}}} = Auth.RestorePasswordForm.call(entity, params)

      password_form =
        case params[:form] do
          nil -> %{valid?: true, errors: []}
          form -> form.call(entity)
        end

      if restore_form.valid? && password_form.valid?,
        do:
          {:ok,
           user
           |> repo.save!(entity ||| %{restore_hash: nil, restore_expire: nil})
           |> Auth.GenerateJWTData.call(repo)},
        else: send_errors(%{restore_form | errors: restore_form.errors ++ password_form.errors})
    end
  end

  def refresh_token(%{repo: repo, schema: schema}) do
    fn %{refresh_token: refresh_token}, _ ->
      case repo.get_by(schema, %{refresh_token: refresh_token}) do
        nil -> send_errors("invalid_refresh_token", 401)
        user -> {:ok, Auth.GenerateJWTData.call(user, repo)}
      end
    end
  end

  def provider_auth(%{repo: repo} = params) do
    fn args, _ ->
      case Auth.Providers.Authorize.call(args, params) do
        {:ok, user} -> {:ok, Auth.GenerateJWTData.call(user, repo)}
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

          form = form.call(entity, %{missing_fields: missing_fields})

          cond do
            form.valid? -> {:ok, user |> repo.save!(entity) |> Auth.GenerateJWTData.call(repo)}
            true -> send_errors(form)
          end
      end
    end
  end
end
