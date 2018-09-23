defmodule DataStoreSupervisor do
  
  use Supervisor
  require Logger  # The application's initialization function

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do

    children = [
#        {Registry, keys: :unique, name: DataPointsStoreRegistry}, 
        {DataPoints, name: DataPoints}
    ]

    Logger.debug "Started supervisor for aplication children: #{inspect children}"
    Supervisor.init(children, strategy: :one_for_one)
  end
end
