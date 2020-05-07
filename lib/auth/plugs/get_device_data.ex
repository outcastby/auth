defmodule Auth.Plugs.GetDeviceData do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn
  import Ext.Utils.Map
  require IEx

  def init(opts) do
    opts
  end

  def call(conn, _opts),
    do: put_private(conn, :absinthe, %{context: get_context(conn) ||| %{device_data: get_device_data(conn)}})

  def get_header(conn, header), do: conn |> get_req_header(header) |> List.first()

  defp get_context(conn), do: conn.private[:absinthe][:context] || %{}

  defp get_device_data(conn),
    do: %{
      browser: Browser.name(conn),
      platform: Browser.full_platform_name(conn),
      ip: client_ip(conn)
    }

  defp client_ip(conn) do
    case __MODULE__.get_header(conn, "x-forwarded-for") do
      nil -> nil
      ips -> ips |> String.split(",") |> List.first()
    end
  end
end
