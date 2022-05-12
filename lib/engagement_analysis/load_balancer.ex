defmodule EngagementAnalysis.LoadBalancer do
  use GenServer
  require Logger

  def start_module() do
    worker_list = []
    index = 0
    Logger.info("Starting Engagement Load Balancer", ansi_color: :yellow)
    GenServer.start_link(__MODULE__, {worker_list, index}, name: __MODULE__)
  end

  def get_tweets(id, tweet) do
    GenServer.cast(__MODULE__, {:receive_tweet, {id, tweet}})
  end

  def send_worker_pid(child) do
    GenServer.cast(__MODULE__, {:add_worker, child})
  end

  def terminate_workers(child_to_kill) do
    GenServer.cast(__MODULE__, {:kill_workers, child_to_kill})
  end

  def delete_from_list(list_of_children_to_kill) do
    if length(list_of_children_to_kill) > 0 do
      pid_to_kill = Enum.at(list_of_children_to_kill, -1)
      safe_termination(pid_to_kill)
      new_list_to_kill = Enum.drop(list_of_children_to_kill,-1)
      delete_from_list(new_list_to_kill)
    else
      :noreply
    end
  end

  def safe_termination(pid_to_kill) do
    if Process.alive?(pid_to_kill) == false do
      IO.inspect("Engagement Load Balancer: The process is not alive")
    else
      {:message_queue_len, list_length} = Process.info(pid_to_kill, :message_queue_len)
      if list_length > 0 do
        Process.send_after(pid_to_kill, {:terminate_work, pid_to_kill}, 5000)
      else
        worker_after_kill = DynamicSupervisor.count_children(EngagementAnalysis.PoolSupervisor).active
        DynamicSupervisor.terminate_child(EngagementAnalysis.PoolSupervisor, pid_to_kill)
#        Logger.info("Engagement Load Balancer: number of workers after kill #{inspect(worker_after_kill)}", ansi_color: :yellow)
      end
    end
  end

  def init(index) do
    {:ok, index}
  end

  def handle_cast({:receive_tweet, {id, tweet}}, state) do
    {worker_list, index} = state
    if length(worker_list) > 0 do
      worker_pid = Enum.at(worker_list, rem(index, length(worker_list)))
      EngagementAnalysis.Worker.receive_tweets(worker_pid, id, tweet)
    end
    {:noreply, {worker_list, index + 1}}
  end

  def handle_cast({:add_worker, child}, state) do
    {worker_list, index} = state
    active_worker_list = Enum.concat(worker_list, [child])
    {:noreply, {active_worker_list, index}}
  end

  def handle_cast({:kill_workers, child_to_kill}, state) do
    {worker_list, index} = state
    list_of_children_to_kill = Enum.take(worker_list, child_to_kill)
    new_worker_list = Enum.drop(worker_list, length(list_of_children_to_kill) * (-1))
    delete_from_list(list_of_children_to_kill)
    {:noreply, {new_worker_list, index}}
  end

  def handle_info({:terminate_work, pid_to_kill}, state) do
    safe_termination(pid_to_kill)
    {:noreply, state}
  end

end
