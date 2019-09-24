defmodule OAuth.SDK.Google.Client do
  use SDK.BaseClient, endpoints: Map.keys(OAuth.SDK.Google.Config.data().endpoints)
  require IEx
  require Logger
end
