defmodule OAuth.GetUserUniqKey do
  def call(%{provider: provider, payload: payload}) do
    module = String.to_atom("Elixir.OAuth.#{Macro.camelize("#{provider}")}.GetUserUniqKey")
    module.call(payload)
  end
end
