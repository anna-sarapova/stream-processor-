defmodule Router do
  use GenServer
  require Logger

  def start_module() do
    IO.inspect("Starting Router")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_tweets(tweet) do
    id = System.unique_integer([:positive, :monotonic])
    GenServer.cast(__MODULE__, {:receive_tweets, {id, tweet}})
  end

  # Server start_module callback
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:receive_tweets, {id, tweet}}, state) do
    EngagementAnalysis.LoadBalancer.get_tweets( id, tweet)
#    IO.inspect("ROUTER: id= #{inspect(id)} tweet= #{inspect(tweet)}")
    EngagementAnalysis.AutoScaler.receive_notification()
    {:noreply, state}
  end
end
