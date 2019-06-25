defmodule Oauth.Sdk.Google.Client do
  use Ext.Sdk.BaseClient, endpoints: Map.keys(Oauth.Sdk.Google.Config.data().endpoints)
  require IEx
  require Logger
end
