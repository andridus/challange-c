defmodule Factory.Base do
  @moduledoc """
    This module gives basic functions to use on Factory Schema and Scenarios
  """

  @doc """
    Get a model by atom, from list
  """
  def get(list, atom) when is_map(list), do: list |> Map.to_list() |> get(atom)

  def get(list, atom) when is_list(list) do
    Keyword.get(list, atom)
  end

  @doc """
    Get a specifyc model id by atom, from list
  """
  def get_id(list, atom) do
    get(list, atom)
    |> case do
      nil -> nil
      v -> v.id
    end
  end

  @doc """
    Convert atom key to string in list
  """
  def string_key_map(map) when is_map(map) do
    map
    |> Map.to_list()
    |> string_key_map()
    |> Map.new()
  end

  def string_key_map([]), do: []

  def string_key_map([head | list]) do
    [string_key_map(head) | string_key_map(list)]
  end

  def string_key_map({key, val}) when is_map(val), do: {to_string(key), string_key_map(val)}

  def string_key_map({key, val}) when is_list(val),
    do: {to_string(key), Enum.map(val, &string_key_map(&1))}

  def string_key_map({key, val}), do: {to_string(key), val}
end
