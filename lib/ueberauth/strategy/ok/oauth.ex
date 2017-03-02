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

  def get(token, url) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url)
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
end
