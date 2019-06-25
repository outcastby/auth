defmodule Oauth.GetUserUniqKey do
  def call(%{provider: provider, payload: payload}) do
    module = String.to_atom("Elixir.Oauth.#{Macro.camelize("#{provider}")}.GetUserUniqKey")
    module.call(payload)
  end
end
