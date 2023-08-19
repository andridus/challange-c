defmodule CumbucaWeb.Response do
  @moduledoc """
    Cieb.Reponse
  """

  alias Phoenix.Controller
  alias Plug.Conn.Utils
  alias CumbucaWeb.StatusMessage

  import Plug.Conn

  def pipe({:ok, data}, conn), do: success(data, conn)
  def pipe({:error, data}, conn), do: error(data, conn)
  def pipe(data, conn) when is_list(data), do: success(data, conn)
  def error(message, conn, status \\ 422)

  def error(%Ecto.Changeset{} = changeset, conn, _status) do
    data0 = parse_changeset(changeset)
    data = %{details: data0, message: :form_error, status: 422}

    conn
    |> put_status(422)
    |> Controller.json(data)
  end

  def error(:not_found, conn, _status) do
    return_error(:not_found, nil, 404, conn)
  end

  def error(:unauth, conn, _status) do
    return_error(:unauthorized, nil, 401, conn)
  end

  def error(data, conn, 200) do
    success(data, conn)
  end

  def error(message, conn, status) do
    return_error(message, nil, status, conn)
  end

  defp return_error(message, _data, status, conn) do
    status = StatusMessage.from_message(message) || status

    conn
    |> put_status(status)
    |> Controller.json(%{
      details: [StatusMessage.from_status(status), message] |> Enum.uniq(),
      message: message,
      status: status
    })
  end

  def success(_data, _conn, _status \\ 200)

  def success({:binary, binary, headers}, conn, status) do
    conn
    |> put_status(status)
    |> Controller.send_download({:binary, binary}, filename: filename_from_headers(headers))
  end

  def success(data, conn, status) do
    conn
    |> put_status(status)
    |> Controller.json(%{
      data: data,
      message: StatusMessage.from_status(status),
      details: [StatusMessage.from_status(status)],
      status: status
    })
  end

  def swagger(path, status, opt \\ [])

  def swagger(path, status, opt) when is_map(opt),
    do: swagger(path, status, data: opt)

  def swagger(path, status, :html) do
    import PhoenixSwagger.Path

    response(
      path,
      status,
      :html,
       %PhoenixSwagger.Schema{ properties: %{}}
    )
  end
  def swagger(path, status, opt) do
    import PhoenixSwagger.Path

    response(
      path,
      status,
      opt[:message] || StatusMessage.from_status(status),
      parse_with_schema(status, opt[:message], opt[:data])
    )
  end

  defp filename_from_headers(headers) do
    with {_, disposition} <- List.keyfind(headers, "content-disposition", 0),
         [_, params] <- :binary.split(disposition, ";"),
         %{"filename" => filename} = _params <- Utils.params(params) do
      filename
    else
      _ -> "__unnamed__"
    end
  end

  defp parse_changeset(changeset),
    do: parse_changeset_error(changeset) |> List.flatten() |> Map.new()

  defp parse_changeset_error(%Ecto.Changeset{changes: changes, errors: errors}) do
    changes =
      changes
      |> Enum.map(fn {_key, value} -> parse_changeset_error(value) end)
      |> List.flatten()

    errors =
      errors
      |> Enum.map(fn {key, {value, _}} -> {key, value} end)

    List.flatten(errors ++ changes)
  end

  defp parse_changeset_error(_), do: []

  defp parse_with_schema(status, message, data) when status in 200..299 do
    message = message || StatusMessage.from_status(status)
    message_map = %{type: :string, example: message}
    details = %{type: :array, example: [message]}
    status = %{type: :integer, example: status}

    %PhoenixSwagger.Schema{
      properties: %{data: data, details: details, message: message_map, status: status}
    }
  end

  defp parse_with_schema(status, message, _data) do
    detail_message = message || StatusMessage.from_status(status)
    message = message || StatusMessage.from_status(status)
    details = %{type: :array, example: [detail_message]}
    message = %{type: :string, example: message}
    status = %{type: :integer, example: status}
    %PhoenixSwagger.Schema{properties: %{details: details, message: message, status: status}}
  end
end
