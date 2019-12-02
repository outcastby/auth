defmodule TestRepo do
  import Ext.Utils.Map

  def get_or_insert!(_, _, _), do: %TestUser{id: 1, email: "test@gmail.com"}
  def get(_, _), do: nil
  def get_by(_, _), do: nil
  def preload(_, _), do: nil
  def insert!(entity), do: entity
  def save!(entity, params), do: entity ||| params
end
