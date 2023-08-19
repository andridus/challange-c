defmodule CumbucaWeb.PageController do
  use CumbucaWeb, :controller

 @doc """
    Home page

    ---| swagger |---
      tag "Static Pages"
      get "/home"
      produces "text/html"
      CumbucaWeb.Response.swagger 200, message: "Home page"
    ---| end |---
  """
  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end
