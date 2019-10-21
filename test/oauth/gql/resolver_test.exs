defmodule OAuth.ResolverTest do
  use ExUnit.Case
  import Mock
  require IEx

  @google_user %{
    "at_hash" => "uWqRMhqrHfbOW7yUHZ5joA",
    "aud" => "google_app_id",
    "azp" => "google_app_id",
    "email" => "test@gmail.com",
    "email_verified" => true,
    "exp" => 1_558_455_010,
    "family_name" => "Test",
    "given_name" => "User",
    "iat" => 1_558_451_410,
    "iss" => "accounts.google.com",
    "jti" => "123456",
    "locale" => "ru",
    "name" => "Test User",
    "picture" => "https://photo.jpg",
    "sub" => "123456789"
  }

  setup_with_mocks([
    {Ecto, [:passthrough], [build_assoc: fn _, _, _ -> %TestAuthorization{} end]},
    {DateTime, [:passthrough], [utc_now: fn -> Ext.Utils.DateTime.from("2018-12-03T08:00:00.000000Z") end]},
    {OAuth.SDK.Facebook.Client, [:passthrough],
     [
       me: fn
         %{payload: %{access_token: "without_email"}} ->
           {:ok,
            %{
              "id" => "fb_user_id",
              "name" => "FB Test name"
            }}

         %{payload: %{access_token: "with_email"}} ->
           {:ok,
            %{
              "id" => "fb_user_id",
              "email" => "fb_first_id@facebook.com",
              "name" => "FB Test name"
            }}
       end,
       app_token: fn _ -> {:ok, %{"access_token" => "access_token"}} end,
       debug_user_token: fn _ ->
         {:ok,
          %{
            "data" => %{
              "app_id" => "facebook_app_id",
              "application" => "Truly Social Games",
              "data_access_expires_at" => 1_566_893_721,
              "expires_at" => 1_559_124_000,
              "is_valid" => true,
              "scopes" => ["email", "public_profile"],
              "type" => "USER",
              "user_id" => "fb_user_id"
            }
          }}
       end
     ]},
    {OAuth.SDK.Google.Client, [:passthrough],
     [
       certs: fn ->
         {:ok,
          %{
            "keys" => [
              %{
                "alg" => "RS256",
                "e" => "AQAB",
                "kid" => "2c3fac16b73fc848d426d5a225ac82bc1c02aefd",
                "kty" => "RSA",
                "n" =>
                  "timkjBhJ0F7fgr5-ySitSoSNmUqYcVKgWaUd52HUYPowNwdw1vOWYHuSVol47ssOOaF7dRjgoVHyo_qNgy7rdlU0pUidiYTB6lwSAQYyvk6WAipkpzWH8cr875BMUREyN5aEy-iKsYTB3HeT-gEnLI697eETZtSB8rwlDvyRy7l0wD1GVj4SKTd4P2a2qNCgCfkZzzKqPgmIrPtwkEZb43Cz-A7AfwyXxrMljTkghKkp4zkFRtXplIGjC5LcPZRLSseTYwHP2pV4AtE5KzYxDmtDmY6RyZaMZc_WXNvKBFcO3Rypo4F63lE2x5f7EIbpATWydXq3CMLitLsPor22ow",
                "use" => "sig"
              },
              %{
                "alg" => "RS256",
                "e" => "AQAB",
                "kid" => "07a082839f2e71a9bf6c596996b94739785afdc3",
                "kty" => "RSA",
                "n" =>
                  "9Y5kfSJyw-GyM4lSXNCVaMKmDdOkYdu5ZhQ7E-8nfae-CPPsx3IZjdUrrv_AoKhM3vsZW_Z3Vucou53YZQuHFpnAa6YxiG9ntpScviU1dhMd4YyUtNYWVBxgNemT9dhhj2i32ez0tOj7o0tGh2Yoo2LiSXRDT-m2zwBImYkBksws4qq_X3jZhlfYkznrCJGjVhKEHzlQy5BBqtQtN5dXFVi-zRZ0-m7oiNW_2wivjw_99li087PNFSeyHpgxjbg30K2qnm1T8gVhnzqf8xnPW9vZFyc_8-3qmbQeDedB8YWyzojM3hDLsHqypP84MSOmejmi0c2b836oc-pI8seXwQ",
                "use" => "sig"
              }
            ]
          }}
       end
     ]},
    {Joken, [:passthrough], [verify: fn _, _ -> {:ok, @google_user} end, peek_claims: fn _ -> {:ok, @google_user} end]}
  ]) do
    google_args = %{
      payload: %{
        id_token:
          "eyJhbGciOiJSUzI1NiIsImtpZCI6IjJjM2ZhYzE2YjczZmM4NDhkNDI2ZDVhMjI1YWM4MmJjMWMwMmFlZmQiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiYXpwIjoiOTcyOTg2MTkxMzM3LWphNGxiamRqbGlmZTByNDZkYXZrM2xiMm92ZG03MnQyLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXVkIjoiOTcyOTg2MTkxMzM3LWphNGxiamRqbGlmZTByNDZkYXZrM2xiMm92ZG03MnQyLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwic3ViIjoiMTEzMTI3MzU5MjgyNjczMzk2MzQxIiwiZW1haWwiOiJtaWhleWtydWdAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImF0X2hhc2giOiJ1V3FSTWhxckhmYk9XN3lVSFo1am9BIiwibmFtZSI6ItCc0LjRhdCw0LjQuyDQmtGA0YPQs9C70LjQuiIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vLTRudEdxMkVBR2NrL0FBQUFBQUFBQUFJL0FBQUFBQUFBQUFBL0FDSGkzcmZhS0lETG42X0RXam4yWEstU01VNWk0YXBrZFEvczk2LWMvcGhvdG8uanBnIiwiZ2l2ZW5fbmFtZSI6ItCc0LjRhdCw0LjQuyIsImZhbWlseV9uYW1lIjoi0JrRgNGD0LPQu9C40LoiLCJsb2NhbGUiOiJydSIsImlhdCI6MTU1ODQ1MTQxMCwiZXhwIjoxNTU4NDU1MDEwLCJqdGkiOiI2OGFiMGNiM2UxMjM4MWZiZDc2NmMyNzcyOTAzNDYyZDYxMWE4ZjZhIn0.azwaSsL5uiIPqbMAoaRf4DHWubCdVJOfCgaBHfVbj29go6fGJ3xT6WNuN-09l4hMGx_X2_bzdwgOgO_gVPqwgYvSWXYoy9UHg2qgd3ZxRMNjyVErP8DQIr3bwmGewHqtIiLABhBjI0lqXGJEJL7eKqBizBj5rlnhlwCYGw8biF8G7tPHanYqO-nooKZfWgQp0ClBb4d5wmi62s-zAxFtMGNJ0bq1EsgzpomLjQ5XPXH2vU6eSclNAugbWH4iQ3H84JGgLtV8iUrHnVEjs_b4dsFlgQSRdBDnMmwc1-quUmgYo42tGj5F1CYIzNWXvL8sZi5T_D4M4281rcKT-Ph2rw"
      },
      provider: :google,
      extra_params: %{owner_id: 1}
    }

    fb_args_with_email = %{payload: %{access_token: "with_email", user_id: "fb_user_id"}, provider: :facebook}

    fb_args_without_email = %{payload: %{access_token: "without_email", user_id: "fb_user_id"}, provider: :facebook}

    {:ok,
     google_args: google_args, fb_args_with_email: fb_args_with_email, fb_args_without_email: fb_args_without_email}
  end

  describe "google auth" do
    test "new user", %{google_args: google_args} do
      with_mock(TestRepo, [:passthrough], get_or_insert!: fn _, _, _ -> %TestUser{id: 1, email: "test@gmail.com"} end) do
        {:ok, user} =
          OAuth.Resolver.authorize(%{
            repo: TestRepo,
            schemas: %{user: TestUser, auth: TestAuthorization},
            required_fields: [:email]
          }).(google_args, %{})

        assert called(
                 TestRepo.get_or_insert!(TestUser, %{email: "test@gmail.com"}, %{email: "test@gmail.com", owner_id: 1})
               )

        assert called(
                 Ecto.build_assoc(%TestUser{email: "test@gmail.com", id: 1}, :test_authorizations, %{
                   provider: :google,
                   uid: "123456789"
                 })
               )

        assert user.email == "test@gmail.com"
      end
    end

    test "existing user", %{google_args: google_args} do
      with_mock(TestRepo, [:passthrough],
        get_by: fn _, _ -> %TestAuthorization{provider: :google, uid: "123456789"} end,
        preload: fn _, _ ->
          %TestAuthorization{
            provider: :google,
            uid: "123456789",
            test_user: %TestUser{id: 1, email: "test@gmail.com"}
          }
        end
      ) do
        {:ok, user} =
          OAuth.Resolver.authorize(%{
            repo: TestRepo,
            schemas: %{user: TestUser, auth: TestAuthorization},
            required_fields: [:email]
          }).(google_args, %{})

        refute called(TestRepo.get_or_insert!(:_, :_, :_))
        refute called(Ecto.build_assoc(:_, :_, :_))
        assert user.email == "test@gmail.com"
      end
    end
  end

  describe "facebook auth" do
    test "new user, facebook with email", %{fb_args_with_email: fb_args_with_email} do
      with_mock(TestRepo, [:passthrough],
        get_or_insert!: fn _, _, _ -> %TestUser{id: 1, email: "fb_first_id@facebook.com"} end
      ) do
        {:ok, user} =
          OAuth.Resolver.authorize(%{
            repo: TestRepo,
            schemas: %{user: TestUser, auth: TestAuthorization},
            required_fields: [:email]
          }).(fb_args_with_email, %{})

        assert called(
                 TestRepo.get_or_insert!(TestUser, %{email: "fb_first_id@facebook.com"}, %{
                   email: "fb_first_id@facebook.com"
                 })
               )

        assert called(
                 Ecto.build_assoc(%TestUser{email: "fb_first_id@facebook.com", id: 1}, :test_authorizations, %{
                   provider: :facebook,
                   uid: "fb_user_id"
                 })
               )

        assert user.email == "fb_first_id@facebook.com"
      end
    end

    test "new user, facebook without email", %{fb_args_without_email: fb_args_without_email} do
      with_mocks([
        {Ecto, [:passthrough],
         [build_assoc: fn _, _, _ -> %TestAuthorization{id: 1, uid: "fb_user_id", provider: :facebook} end]},
        {TestRepo, [:passthrough], save!: fn _, _ -> %TestUser{id: 1, email: nil} end}
      ]) do
        response =
          OAuth.Resolver.authorize(%{
            repo: TestRepo,
            schemas: %{user: TestUser, auth: TestAuthorization},
            required_fields: [:email]
          }).(fb_args_without_email, %{})

        refute called(TestRepo.get_or_insert!(TestUser, :_, :_))
        assert called(TestRepo.save!(TestUser.__struct__(), :_))

        assert called(
                 Ecto.build_assoc(%TestUser{email: nil, id: 1}, :test_authorizations, %{
                   provider: :facebook,
                   uid: "fb_user_id"
                 })
               )

        assert response ==
                 {:error,
                  [
                    message: :authorization_not_complete,
                    details: %{
                      "missingFields" => [:email],
                      "oauthData" => %{"provider" => :facebook, "uid" => "fb_user_id"}
                    },
                    code: 400
                  ]}
      end
    end

    test "existing user", %{fb_args_without_email: fb_args_without_email} do
      with_mock(TestRepo, [:passthrough],
        get_by: fn _, _ -> %TestAuthorization{provider: :facebook, uid: "fb_user_id"} end,
        preload: fn _, _ ->
          %TestAuthorization{
            provider: :facebook,
            uid: "fb_user_id",
            test_user: %TestUser{id: 1, email: "test@test.com"}
          }
        end
      ) do
        {:ok, user} =
          OAuth.Resolver.authorize(%{
            repo: TestRepo,
            schemas: %{user: TestUser, auth: TestAuthorization},
            required_fields: [:email]
          }).(fb_args_without_email, %{})

        refute called(TestRepo.get_or_insert!(:_, :_, :_))
        refute called(Ecto.build_assoc(:_, :_, :_))
        assert user.email == "test@test.com"
      end
    end
  end
end
