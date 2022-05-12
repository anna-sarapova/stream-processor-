defmodule RetweetExtracting.PoolSupervisor do
  use DynamicSupervisor

  def start_module() do
    IO.inspect("Hi, I'm Retweet Pool Supervisor")
    supervisor = DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
    start_worker(10)
    supervisor
  end

  def child_spec(index) do
    %{
      id: EngagementWorker,
      start: {RetweetExtracting.Worker, :start_module, [index + 1]}
    }
  end

  def start_worker(auto_scaler_nr) when auto_scaler_nr == 0 do
    :work_lazy_pinguin
  end

  def start_worker(auto_scaler_nr) do
    active_children = DynamicSupervisor.count_children(__MODULE__).active
    case auto_scaler_nr do
      auto_scaler_nr when (auto_scaler_nr > 0) ->
        {:ok, child} = DynamicSupervisor.start_child(__MODULE__, child_spec(active_children))
        RetweetExtracting.LoadBalancer.send_worker_pid(child)
        start_worker(auto_scaler_nr-1)

      # TODO safe termination
      auto_scaler_nr when (auto_scaler_nr < 0) ->
        RetweetExtracting.LoadBalancer.terminate_workers(auto_scaler_nr)
      _ ->
        :do_nothing
    end
  end

  def init(_) do
    DynamicSupervisor.init(max_restarts: 200, strategy: :one_for_one)
  end
end

