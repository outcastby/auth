defmodule OAuth.SDK.Facebook.Client do
  use SDK.BaseClient, endpoints: Map.keys(OAuth.SDK.Facebook.Config.data().endpoints)
  require IEx
  require Logger
end
