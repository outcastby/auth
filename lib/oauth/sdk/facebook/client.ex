defmodule Oauth.Sdk.Facebook.Client do
  use Sdk.BaseClient, endpoints: Map.keys(Oauth.Sdk.Facebook.Config.data().endpoints)
  require IEx
  require Logger
end
