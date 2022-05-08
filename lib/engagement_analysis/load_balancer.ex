defmodule EngagementAnalysis.LoadBalancer do
  use GenServer
  require Logger

  def start_module() do
    worker_list = []
    index = 0
    Logger.info("Starting Load Balancer", ansi_color: :yellow)
    GenServer.start_link(__MODULE__, {worker_list, index}, name: __MODULE__)
  end

  def get_tweets(id, tweet) do
    GenServer.cast(__MODULE__, {:receive_tweet, {id, tweet}})
  end

  def send_worker_pid(child) do
    #    IO.inspect("Load Balancer: Child #{inspect(child)}")
    GenServer.cast(__MODULE__, {:add_worker, child})
  end

  def terminate_workers(child_to_kill) do
    GenServer.cast(__MODULE__, {:kill_workers, child_to_kill})
  end

  def init(index) do
    {:ok, index}
  end

  def handle_cast({:receive_tweet, {id, tweet}}, state) do
#    IO.inspect("LoadBalancer: id= #{inspect(id)}, tweet= #{inspect(tweet)}")
    {worker_list, index} = state
    if length(worker_list) > 0 do
      worker_pid = Enum.at(worker_list, rem(index, length(worker_list)))
      #      IO.inspect("Load Balancer: Worker pid #{inspect(worker_pid)}")
      EngagementAnalysis.Worker.receive_tweets(worker_pid, id, tweet)
    end
    {:noreply, {worker_list, index + 1}}
  end

  def handle_cast({:add_worker, child}, state) do
    {worker_list, index} = state
    active_worker_list = Enum.concat(worker_list, [child])
    #    IO.inspect("Load Balancer: Child list #{inspect(active_worker_list)}")
    {:noreply, {active_worker_list, index}}
  end

  def handle_cast({:kill_workers, child_to_kill}, state) do
    {worker_list, index} = state
    list_of_children_to_kill = Enum.take(worker_list, child_to_kill)
    IO.inspect("Load Balancer: Children to kill #{inspect(list_of_children_to_kill)}")
#    delete_from_list(list_of_children_to_kill)
    new_worker_list = Enum.drop(worker_list, length(list_of_children_to_kill) * (-1))
    {:noreply, {new_worker_list, index}}
  end
end
