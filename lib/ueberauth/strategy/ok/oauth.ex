defmodule Ueberauth.Strategy.Ok.OAuth do
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "http://api.ok.ru/fb.do",
    authorize_url: "https://connect.ok.ru/oauth/authorize",
    token_url: "https://api.odnoklassniki.ru/oauth/token.do"
  ]

  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Ok.OAuth)
    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)
    OAuth2.Client.new(opts)
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token!(params \\ [], opts \\ []) do
    client =
      opts
      |> client
      |> OAuth2.Client.get_token!(params)
    client.token
  end
  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  def get(conn, token) do
    OAuth2.Client.get(client, "https://api.ok.ru/fb.do?#{user_query(conn, token)}")
  end

  defp user_query(conn, token) do
    access_token = Map.fetch!(token, :access_token)
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Ok.OAuth)
    client_public = Keyword.get(config, :client_public)
    client_secret = Keyword.get(config, :client_secret)
    URI.encode_query(%{
      application_key: client_public,
      format: "json",
      method: "users.getCurrentUser",
      access_token: access_token,
      sig: sig(access_token, client_public, client_secret)
    })
  end

  defp sig(access_token, client_public, client_secret) do
    secret_key = md5(access_token <> client_secret)
    md5("application_key=#{client_public}format=jsonmethod=users.getCurrentUser#{secret_key}")
  end

  defp md5(str), do: str |> :crypto.md5 |> Base.encode16 |> String.downcase
end
