defmodule RestApiWeb.Router do
  use RestApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RestApiWeb do
    pipe_through :api

    # added by JC
    get "/data", DataController, :index
  end
end
