defmodule Ueberauth.Strategy.Ok do
  @moduledoc """
  ok.ru Strategy for Überauth.
  """

  use Ueberauth.Strategy, default_scope: "GET_EMAIL"
  alias Ueberauth.Auth.Info

  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts =
      [scope: scopes]
      |> with_optional(:layout, conn)
      |> with_optional(:state, conn)
      |> Keyword.put(:response_type, "code")
      |> Keyword.put(:redirect_uri, callback_url(conn))
    redirect!(conn, Ueberauth.Strategy.Ok.OAuth.authorize_url!(opts))
  end

  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.Ok.OAuth.get_token!([code: code], opts)

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  def info(conn) do
    user = conn.private.ok_user
    %Info{
      email: user["email"],
      first_name: user["first_name"],
      image: user["pic_3"] || user["pic_2"] || user["pic_1"],
      last_name: user["first_name"],
      name: user["name"]
    }
  end

  defp with_optional(opts, key, conn) do
    if option(conn, key), do: Keyword.put(opts, key, option(conn, key)), else: opts
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :ok_token, token)
    case Ueberauth.Strategy.Ok.OAuth.get(conn, token) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user}} when status_code in 200..399 ->
        put_private(conn, :ok_user, user)
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end
end
