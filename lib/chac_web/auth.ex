defmodule ChacWeb.Auth do
  @moduledoc """
    Manages the Authenticated User
  """
  use Guardian, otp_app: :chac
  alias Chac.Core.Account
  alias ChacWeb.Auth.Plug

  @doc false
  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(%{"sub" => id}) do
    Account.Api.get(id)
  end

  @doc """
    Get permission from authed user
  """
  def get_permission(_conn), do: nil

  @doc """
    Get authed user data
  """
  def get_user(conn), do: Plug.current_resource(conn)
end
