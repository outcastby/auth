use Mix.Config

config :oauth, :oauth,
  google_client_id: System.get_env("GOOGLE_CLIENT_ID"),
  facebook_client_id: System.get_env("FACEBOOK_CLIENT_ID")
