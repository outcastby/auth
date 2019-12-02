defmodule Auth.GenerateJWTData do
  @moduledoc false

  def call(user, repo) do
    %{refresh_token: refresh_token} =
      repo.save!(user, %{
        refresh_token: Ext.Utils.Repo.generate_uniq_hash(user.__struct__, :refresh_token, 30, repo)
      })

    access_token = Auth.Token.generate_and_sign!(%{"id" => user.id, "schema" => user.__struct__})

    %{access_token: access_token, refresh_token: refresh_token, current_user: user}
  end
end
