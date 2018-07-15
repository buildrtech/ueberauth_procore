# Überauth Procore

> Procore OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Procore API](https://api.procore.com).

1. Add `:ueberauth_procore` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_procore, "~> 0.5"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_procore]]
    end
    ```

1. Add Procore to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        procore: {Ueberauth.Strategy.Procore, []}
      ]
    ```

    You can optionally restrict authentication by providing your team ID. [Find your Procore team ID here](https://api.procore.com/methods/auth.test/test). Note that this is NOT your team's Procore domain name!

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        procore: {Ueberauth.Strategy.Procore, [team: "0ABCDEF"]}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Procore.OAuth,
      client_id: System.get_env("SLACK_CLIENT_ID"),
      client_secret: System.get_env("SLACK_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/procore

Or with options:

    /auth/procore?scope=users:read

By default the requested scope is "users:read". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    procore: {Ueberauth.Strategy.Procore, [default_scope: "users:read,users:write"]}
  ]
```

## License

Please see [LICENSE](https://github.com/ueberauth/ueberauth_procore/blob/master/LICENSE) for licensing details.

