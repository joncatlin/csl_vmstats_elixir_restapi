defmodule Start do
  
  use Application
  require Logger  # The application's initialization function

  def start(_type, _args) do
    Logger.debug "Starting application supervisor"
    DataStoreSupervisor.start_link(name: DataStoreSupervisor)

#     import Supervisor.Spec, warn: false
    
#     children = [
# #      {Registry, keys: :unique, name: Registry.ViaTest}
# #      supervisor(Registry, [:unique, :jon])
# #      supervisor(Registry, keys: :unique, name: Registry.ViaTest)
#         {DataPoints, name: DataPoints}
#     ]

#     Logger.debug "Application starting with children: #{inspect children}"

#     Supervisor.init(children, strategy: :one_for_one)

#     # Starting registry outside a supervision tree until I can figure out what is wrong
#     {:ok, _} = Registry.start_link(keys: :unique, name: DataPointsStoreRegistry)
  end
end