# OAuth
OAuth resolver for Graphql

## Installation

1. Add `oauth` to your list of dependencies in `mix.exs`.
    ```elixir
    def deps do
      [
        {:oauth, git: "https://github.com/outcastby/oauth.git"}
      ]
    end
    ```

2. Update dependencies by running:
    ```sh
    $ mix deps.get
    ```
## Setup server
3. Fill in config for oauth (how to configure oauth apps for providers see below):
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "",
      facebook_client_id: "",
      facebook_client_secret: "",
      twitter_consumer_key: "",
      twitter_consumer_secret: "",
      twitter_access_token: "",
      twitter_access_token_secret: ""
    ```
4. Create table for authorization records. Example:
    * migration:
        ```elixir
        defmodule Repo.Migrations.CreateAuthorizations do
          use Ecto.Migration
        
          def change do
            create table(:authorizations) do
              add(:user_id, references(:users, on_delete: :delete_all))
              add(:provider, :smallint)
              add(:uid, :string)
              timestamps(type: :timestamptz)
            end
        
            create(index(:authorizations, [:user_id]))
            create(unique_index(:authorizations, [:provider, :uid]))
          end
        end
        ```
    * schema:
        ```elixir
        defmodule Authorization do
          @moduledoc false
          use Schema
      
          import EctoEnum, only: [defenum: 2]
          defenum ProviderEnum, facebook: 0, google: 1, twitter: 2
        
          schema "authorizations" do
            field :provider, ProviderEnum
            field :uid, :string
            belongs_to :user, User
            timestamps()
          end
          
          def changeset(struct, params \\ %{}) do
            struct
            |> cast(params, [:provider, :uid, :user_id])
          end
        end
        ```
5. Add association to User schema: 
    ```elixir
    has_many :authorizations, Authorization, on_replace: :delete
    ```
6. Create initializer for oauth (path: `lib/bomb_brawl/initializers/oauth.ex`) and add `Ext.RunInitializers.call(<app_name>)` to `start` function of `application.ex` 
    ```elixir
    defmodule Initializers.Oauth do
      @moduledoc false
    
      def call do
        ExTwitter.configure(
          consumer_key: Application.get_env(:bomb_brawl, :oauth)[:twitter_consumer_key],
          consumer_secret: Application.get_env(:bomb_brawl, :oauth)[:twitter_consumer_secret],
          access_token: Application.get_env(:bomb_brawl, :oauth)[:twitter_access_token],
          access_token_secret: Application.get_env(:bomb_brawl, :oauth)[:twitter_access_token_secret53]
        )
      end
    end
    ```
7. If it necessary create form for required fields. Example:
    ```elixir
    defmodule OAuth.SetEmailForm do
      @moduledoc false
      use Ext.BaseForm
    
      Ext.BaseForm.schema "" do
        field(:email, :string, required: true)
        field(:first_name, :string, required: true)
      end
    
      def changeset(params, context \\ %{}) do
        build_args(params, context)
        |> validate_required(context.missing_fields)
        |> Ext.Validators.Email.call(%{field: :email, message: "Invalid email format"})
        |> Ext.Validators.Uniq.call(%{schema: User, repo: Repo, fields: [:email], message: "Not unique"})
      end
    end
    ```
#### Mutations
1. Start authentication by provider:
    ```elixir
    enum(:provider_types, values: [:facebook, :google, :twitter])
   
    field :provider_auth, type: :user do
          arg :payload, non_null(:snake_keys_json)
          arg :provider, non_null(:provider_types)
    
          resolve OAuth.Resolver.authorize(%{
                    repo: Repo,
                    schemas: %{user: User, auth: Authorization},
                    required_fields: [:email, :first_name]
                  })
        end
    ```
    Payload example:
    * Google: 
        ```json
        {"id_token": "fake_google_user_token"}
        ```
    * Facebook: 
        ```json
        {
          "accessToken": "fake_facebook_user_token",
          "userID": "fake_user_id",
          "expiresIn": 1000,
          "signedRequest": "fake_signed_request",
          "data_access_expiration_time": 1577090601
        }
        ```
    * Twitter:
    ```json
    {"oauth_token": "fake_oauth_token", "oauth_verifier": "fake_oauth_verifier"}
    ```
2. Finish authentication and check required fields: 
    ```elixir
    input_object :oauth_user_params do
      field :email, :string
      field :first_name, :string
    end
   
    input_object :oauth_data_params do
      field :uid, :string
      field :provider, :provider_types
    end
    
    field :complete_oauth, type: :user do
          arg :entity, non_null(:oauth_user_params)
          arg :oauth_data, non_null(:oauth_data_params)
    
          resolve OAuth.Resolver.complete(%{
                    repo: Repo,
                    schemas: %{user: User, auth: Authorization},
                    required_fields: [:email, :first_name],
                    form: Form # Form for validate required fields
                  })
        end
    ```
3. Mutation for getting twitter authenticate url:
    ```elixir
    field :twitter_authenticate_url, type: :string do
          arg :callback_url, non_null(:string)
    
          resolve &OAuth.Resolver.twitter_authenticate_url/2
        end
    ```
#### Setup Google oauth 
1. Create new google project (https://console.developers.google.com). 
2. On tab `OAuth consent screen` fill in `Application name` and `Authorized domains` fields.
3. On tab `Credentials` create `OAuth client ID`. Choose `Web application` type. Fill in 
   `Authorized JavaScript origins` field by urls of your client app.
4. In config/config.exs, add `google_client_id`:
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "Client Id",
      facebook_client_id: "",
      facebook_client_secret: "",
      twitter_consumer_key: "",
      twitter_consumer_secret: "",
      twitter_access_token: "",
      twitter_access_token_secret: ""
    ```
   
#### Setup Facebook oauth
1. Create new facebook application (https://developers.facebook.com)
2. On tab `Settings > Basic` fill in the following fields:
    * `App Domains` - urls of your client app
    * `Privacy Policy URL` - link to Privacy Policy of your Company  
    * `Site URL` - main domain
3. In config/config.exs, add `facebook_client_id` and `facebook_client_secret`:
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "",
      facebook_client_id: "App ID",
      facebook_client_secret: "App Secret",
      twitter_consumer_key: "",
      twitter_consumer_secret: "",
      twitter_access_token: "",
      twitter_access_token_secret: ""
    ```

#### Setup Twitter oauth
1. Create new twitter application (https://developers.facebook.com)
2. Fill in the following fields:
    * `Website URL` - main domain
    * `Enable Sign in with Twitter` - should be checked
    * `Callback URLs` - after clicking to sign in button, twitter redirect user to this url with oauth data in params
    * `Terms of service URL` and `Privacy policy URL` - required if you'd like to enable advanced permission settings.
    * `Tell us how this app will be used` - example: "This application be used only for sign in in our corporative administration dashboard and get base information for create new user."
3. Setup app Permissions. `Access permission`: `Read-only`. `Request email address from users` should be checked
4. In config/config.exs, add `twitter_consumer_key`, `twitter_consumer_secret`, `twitter_access_token` and `twitter_access_token_secret`:
    ```elixir
    config :bomb_brawl, :oauth,
      google_client_id: "",
      facebook_client_id: "",
      facebook_client_secret: "",
      twitter_consumer_key: "API key",
      twitter_consumer_secret: "API secret key",
      twitter_access_token: "Access token",
      twitter_access_token_secret: "Access token secret"
    ```
## Setup client (for internal use)
See https://trulysocialgames.atlassian.net/wiki/spaces/BBN/pages/1420492906/Auth+and+OAuth