defmodule Auth.Resolver.AuthTest do
  use Auth.ConnCase

  setup_with_mocks [{Ext.Utils.Repo, [:passthrough], [generate_uniq_hash: fn _, _, _, _ -> "uniq_hash" end]}] do
    :ok
  end

  test ".sign_in" do
    with_mocks [
      {TestRepo, [:passthrough],
       [
         get_by: fn _, _ ->
           %TestUser{id: 1, email: "test@email.com", encrypted_password: Bcrypt.hash_pwd_salt("123qwe")}
         end
       ]}
    ] do
      {:ok, %{access_token: access_token, refresh_token: refresh_token, current_user: current_user}} =
        Auth.Resolver.sign_in(%{repo: TestRepo, schema: TestUser}).(
          %{email: "test@email.com", password: "123qwe"},
          %{}
        )

      {:ok, payload} = Auth.Token.verify_and_validate(access_token)

      assert_lists(Map.keys(payload), ["exp", "id", "schema"])
      assert payload["id"] == 1
      assert current_user.email == "test@email.com"
      assert refresh_token == "uniq_hash"
    end
  end

  describe "sign_up" do
    test "open" do
      with_mocks([
        {Ext.GQL.Resolvers.Base, [:passthrough],
         [create: fn _ -> fn _, _ -> {:ok, %TestUser{id: 1, email: "test@email.com"}} end end]}
      ]) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token, current_user: user}} =
          Auth.Resolver.sign_up(%{repo: TestRepo, schema: TestUser}).(
            %{entity: %{email: "test@email.com", password: "123qwe", password_confirmation: "123qwe"}},
            %{}
          )

        assert access_token
        assert user.email == "test@email.com"
        assert refresh_token == "uniq_hash"
      end
    end

    test "closed" do
      with_mocks([
        {Application, [:passthrough], [get_env: fn :auth, :auth -> [close_sign_up: [TestUser]] end]}
      ]) do
        {:error, [message: message, code: 400]} = Auth.Resolver.sign_up(%{repo: TestRepo, schema: TestUser}).(%{}, %{})

        assert message == "sign_up_closed"
      end
    end
  end

  test ".refresh_token" do
    resp = Auth.Resolver.refresh_token(%{repo: TestRepo, schema: TestUser}).(%{refresh_token: "refresh_token"}, %{})

    assert resp == {:error, [message: "invalid_refresh_token", code: 401]}
  end

  describe ".forgot_password" do
    test "user exist" do
      with_mocks [
        {TestRepo, [:passthrough],
         [
           get_by: fn _, _ ->
             %TestUser{id: 1, email: "test@email.com"}
           end
         ]}
      ] do
        resp =
          Auth.Resolver.forgot_password(%{repo: TestRepo, schema: TestUser, send_caller: fn _, _ -> nil end}).(
            %{email: "test@email.com", restore_url: ""},
            %{}
          )

        assert resp == {:ok, "ok"}
      end
    end

    test "user not exist" do
      resp =
        Auth.Resolver.forgot_password(%{repo: TestRepo, schema: TestUser, send_caller: fn _, _ -> nil end}).(
          %{email: "test@email.com", restore_url: ""},
          %{}
        )

      assert resp ==
               {:error,
                [message: "Validation Error", code: 400, details: %{"email" => ["Email test@email.com not found"]}]}
    end
  end

  describe ".restore_password" do
    test "user exist" do
      with_mocks [
        {TestRepo, [:passthrough],
         [
           get_by: fn _, _ ->
             %TestUser{id: 1, restore_hash: "123qweasdzxc", restore_expire: ~U[2019-09-19 13:00:00.000000Z]}
           end,
           save!: fn user, _ -> user end
         ]},
        {DateTime, [:passthrough], utc_now: fn -> ~U[2019-09-19 13:00:00.000000Z] end}
      ] do
        {:ok, %{access_token: _, refresh_token: _, current_user: user}} =
          Auth.Resolver.restore_password(%{repo: TestRepo, schema: TestUser}).(
            %{entity: %{restore_hash: "123qweasdzxc", password: "123qwe", password_confirmation: "123qwe"}},
            %{}
          )

        assert called(
                 TestRepo.save!(user, %{
                   restore_hash: nil,
                   restore_expire: nil,
                   password: "123qwe",
                   password_confirmation: "123qwe"
                 })
               )
      end
    end

    test "user not exist" do
      resp =
        Auth.Resolver.restore_password(%{repo: TestRepo, schema: TestUser}).(
          %{entity: %{restore_hash: "123qweasdzxc", password: "123qwe", password_confirmation: "123qwe"}},
          %{}
        )

      assert resp ==
               {:error, [message: "Validation Error", code: 400, details: %{"password" => ["Invalid restore hash"]}]}
    end
  end
end
