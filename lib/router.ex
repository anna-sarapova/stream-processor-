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
    EngagementAnalysis.AutoScaler.receive_notification()
    RetweetExtracting.LoadBalancer.get_tweets(id, tweet)
    RetweetExtracting.AutoScaler.receive_notification()
    SentimentAnalysis.LoadBalancer.get_tweets(id, tweet)
    SentimentAnalysis.AutoScaler.receive_notification()
    Aggregator.add_tweet_info(id, tweet)
    {:noreply, state}
  end
end
