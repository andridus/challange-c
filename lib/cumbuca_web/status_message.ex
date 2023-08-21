defmodule CumbucaWeb.StatusMessage do
  @moduledoc """
    Messages to response
  """
  require Logger

  @messages [
    {200, :ok},
    {201, :created},
    {400, :bad_request},
    {401, :unauthorized},
    {403, :forbidden},
    {404, :not_found},
    {409, :conflict},
    {422, :form_error},
    {500, :internal_server_error},
    ## account
    {400, :account_not_found},
    {400, :account_was_deleted},
    {400, :account_id_is_nil},
    {400, :password_dont_match},
    {400, :password_length_should_be_four},
    ## auth
    {400, :cpf_or_password_invalid}
  ]
  def from_message("param_" <> _key), do: 400

  def from_message(message) do
    @messages
    |> List.flatten()
    |> Enum.find(fn
      {_status, ^message} -> true
      {_status, message0} -> to_string(message0) == message
    end)
    |> case do
      nil ->
        Logger.error("Not found message '#{message}'")
        400

      {status, _} ->
        status
    end
  end

  def from_status(status) do
    @messages
    |> List.flatten()
    |> Enum.find(fn
      {^status, _message} -> true
      _ -> false
    end)
    |> case do
      nil ->
        Logger.error("Not found status '#{status}'")
        400

      {_status, message} ->
        message
    end
  end
end
