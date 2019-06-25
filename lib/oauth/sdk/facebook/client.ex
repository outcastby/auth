defmodule Oauth.Sdk.Facebook.Client do
  use Ext.Sdk.BaseClient, endpoints: Map.keys(Oauth.Sdk.Facebook.Config.data().endpoints)
  require IEx
  require Logger
end
