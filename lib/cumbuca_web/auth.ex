defmodule CumbucaWeb.Auth do
  @moduledoc """
    Manages the Authenticated User
  """

  @doc """
    Get permission from authed user
  """
  def get_permission(_conn), do: nil

  @doc """
    Get authed user data
  """
  def get_user(_conn), do: nil

  @doc """
    Encode and signin - from guardian
  """
  def encode_and_sign(_conn), do: nil
end
