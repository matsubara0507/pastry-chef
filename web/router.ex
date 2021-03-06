defmodule PastryChefTest.Router do
  use PastryChefTest.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PastryChefTest do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/new", PageController, :index
    get "/edit/:id", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", PastryChefTest do
    pipe_through :api

    get "/branches", BranchesController, :branches

    get "/instances", InstancesController, :instances
    get "/instances/:id", InstancesController, :instance
    post "/instances", InstancesController, :create
    put "/instances/:id/deploy", InstancesController, :deploy
    put "/instances/:id/rename/:name", InstancesController, :rename
    put "/instances/:id/state/:state", InstancesController, :change_state
  end
end
