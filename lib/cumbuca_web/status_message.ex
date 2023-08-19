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
      {400, :not_found},
      {400, :id_is_nil},
      {400, :was_deleted},
      {422, :form_error},
      {200, :ok}
    ]
  def from_message(message) do
    @messages
    |> List.flatten()
    |> Enum.find(fn
      {_status, ^message} -> true
      _ -> false
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
        Logger.error("Not found message '#{status}'")
        400

      {_status, message} ->
        message
    end
  end
end