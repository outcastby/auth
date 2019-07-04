defmodule TestRepo do
  def get_or_insert!(_, _, _), do: %TestUser{id: 1, email: "test@gmail.com"}
  def get_by(_, _), do: nil
  def preload(_, _), do: nil
  def insert!(entity), do: entity
  def save!(_, _), do: nil
end
