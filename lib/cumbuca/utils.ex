defmodule Cumbuca.Utils do
  @moduledoc """
    Set of common functions to use in Cumbuca application
  """
  @doc """
    Get param
  """
  def get_param(params, param) do
    Access.fetch(params, param)
  end

  @doc """
    return datetime now truncate second
  """
  def now_sec do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end

  @doc """
    return iso8601 from datetime now
  """
  def dateime_to_iso8601 do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  @doc """
    return only visible fields, permission based
  """
  def visible_fields({:error, error}, _permission), do: {:error, error}

  def visible_fields({:ok, %{__struct__: entity} = model}, permission) do
    {:ok, Map.take(model, entity.bee_permission(permission))}
  end

  @doc """
    Remove nil fields
  """
  def remove_nil_fields(params) do
    for({key, value} <- params, !is_nil(value) && value != "nil", into: %{}, do: {key, value})
  end

  @doc """
    Parse changeset error to string
  """
  def parse_changeset_string(changeset, label \\ []) do
    message = fn x ->
      [label, to_string(elem(x, 1))]
      |> List.flatten()
      |> Enum.join(": ")
    end

    parse_changeset(changeset)
    |> Enum.map_join(";", &message.(&1))
  end

  @doc """
    Parse changeset error
  """
  def parse_changeset(changeset),
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

  @doc """
    Parse string to date
  """
  def parse_to_date(nil), do: nil

  def parse_to_date(txt) when is_bitstring(txt) do
    Date.from_iso8601!(txt)
  rescue
    _ -> nil
  end
end
