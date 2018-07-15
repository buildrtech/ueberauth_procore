defmodule Ueberauth.Strategy.Procore do
  @moduledoc """
  Implements an ÜeberauthProcore strategy for authentication with procore.com.

  When configuring the strategy in the Üeberauth providers, you can specify some defaults.

  * `uid_field` - The field to use as the UID field. This can be any populated field in the info struct. Default `:email`
  * `oauth2_module` - The OAuth2 module to use. Default Ueberauth.Strategy.Procore.OAuth

  ````elixir

  config :ueberauth, Ueberauth,
    providers: [
      procore: { Ueberauth.Strategy.Procore, [uid_field: :id] }
    ]
  """
  use Ueberauth.Strategy, uid_field: :id,
                          oauth2_module: Ueberauth.Strategy.Procore.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  # When handling the request just redirect to Procore
  @doc false
  def handle_request!(conn) do
    opts = []
    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    callback_url = callback_url(conn)
    callback_url =
      if String.ends_with?(callback_url, "?"), do: String.slice(callback_url, 0..-2), else: callback_url

    opts = Keyword.put(opts, :redirect_uri, callback_url)
    module = option(conn, :oauth2_module)

    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  # When handling the callback, if there was no errors we need to
  # make two calls. The first, to fetch the procore auth is so that we can get hold of
  # the user id so we can make a query to fetch the user info.
  # So that it is available later to build the auth struct, we put it in the private section of the conn.
  @doc false
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module  = option(conn, :oauth2_module)
    params  = [code: code]
    redirect_uri = get_redirect_uri(conn)
    options = %{
      options: [
        client_options: [redirect_uri: redirect_uri]
      ]
    }
    token = apply(module, :get_token!, [params, options])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      conn
      |> store_token(token)
      |> fetch_companies(token)
      |> fetch_user(token)
    end
  end

  # If we don't match code, then we have an issue
  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  # We store the token for use later when fetching the procore auth and user and constructing the auth struct.
  @doc false
  defp store_token(conn, token) do
    put_private(conn, :procore_token, token)
  end

  # Remove the temporary storage in the conn for our data. Run after the auth struct has been built.
  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:procore_user, nil)
    |> put_private(:procore_token, nil)
  end

  # The structure of the requests is such that it is difficult to provide cusomization for the uid field.
  # instead, we allow selecting any field from the info struct
  @doc false
  def uid(conn) do
    Map.get(info(conn), option(conn, :uid_field))
  end

  @doc false
  def credentials(conn) do
    token = conn.private.procore_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: [],
    }
  end

  @doc false
  def info(conn) do
    user = conn.private[:procore_user]

    %Info{
      email: user["email_address"],
      first_name: user["first_name"],
      last_name: user["last_name"],
    }
  end

  @doc false
  def extra(conn) do
    user = conn.private[:user]

    %Extra {
      raw_info: %{
        companies: conn.private[:procore_companies],
        token: conn.private[:procore_token],
        user: conn.private[:procore_user],
        job_title: user["job_title"],
        is_employee: user["is_employee"],
        business_phone: user["business_phone"],
        mobile_phone: user["mobile_phone"],
      }
    }
  end

  defp fetch_companies(conn, token) do
    case Ueberauth.Strategy.Procore.OAuth.get(token, "/companies") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: companies}} when status_code in 200..399 ->
        put_private(conn, :procore_companies, companies)
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp fetch_user(conn, token) do
    first_company = conn.private[:procore_companies]
    case Ueberauth.Strategy.Procore.OAuth.get(token, "/companies/#{first_company.id}/me") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user}} when status_code in 200..399 ->
        put_private(conn, :procore_user, user)
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Map.get(options(conn), key, Map.get(default_options(), key))
  end

  defp get_redirect_uri(%Plug.Conn{} = conn) do
    config = Application.get_env(:ueberauth, Ueberauth)
    redirect_uri = Keyword.get(config, :redirect_uri)

    if is_nil(redirect_uri) do
      callback_url(conn)
    else
      redirect_uri
    end
  end
end
