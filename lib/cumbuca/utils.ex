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
end
