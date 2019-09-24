defmodule OAuth.Twitter.GetUserDetails do
  require IEx

  def call(_) do
    user = ExTwitter.verify_credentials(include_email: true)

    %OAuth.User{
      email: user.email,
      full_name: user.name,
      id: user.id_str
    }
  end
end
