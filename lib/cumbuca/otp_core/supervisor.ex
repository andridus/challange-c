# defmodule Cumbuca.Worker.Supervisor do
#   use DynamicSupervisor

#   def start_link(init) do
#     DynamicSupervisor.start_link(__MODULE__, init, name: __MODULE__)
#   end

#   def init(_) do
#     DynamicSupervisor.init(strategy: :one_for_one)
#   end
# end
