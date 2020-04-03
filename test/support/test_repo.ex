defmodule TestRepo do
  import Ext.Utils.Map

  def get_or_insert!(schema, query, _), do: schema.__struct__ ||| %{id: 1} ||| query
  def get(_, _), do: nil
  def get_by(_, _), do: nil
  def preload(_, _), do: nil
  def insert!(entity), do: entity
  def save!(entity, params), do: entity ||| params
end
