defmodule Auth.CheckCloseSignUp do
  def call(schema), do: schema in (Application.get_env(Mix.Project.config()[:app], :auth)[:close_sign_up] || [])
end
