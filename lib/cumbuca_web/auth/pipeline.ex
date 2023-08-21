defmodule CumbucaWeb.Auth.Pipeline do
  @moduledoc """
  Auth pipeline that restricts access and assigns privilege level
  """
  use Guardian.Plug.Pipeline,
    otp_app: :kirby_project,
    module: CumbucaWeb.Auth,
    error_handler: CumbucaWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
  # plug Guardian.Plug.EnsureAuthenticated
end
