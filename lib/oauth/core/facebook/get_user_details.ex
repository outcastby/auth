defmodule Oauth.Facebook.GetUserDetails do
  require Logger
  require IEx

  def call(%{access_token: access_token}) do
    request = %Ext.Sdk.Request{
      payload: %{fields: "id,email,first_name,last_name,name", access_token: access_token}
    }

    case Oauth.Sdk.Facebook.Client.me(request) do
      {:ok, fb_user} ->
        %Oauth.User{
          email: fb_user["email"],
          first_name: fb_user["first_name"],
          last_name: fb_user["last_name"],
          full_name: fb_user["name"],
          id: fb_user["sub"]
        }

      {:error, response} ->
        Logger.error("Error get info about player for facebook, message - #{inspect(response)}")
        nil
    end
  end
end
