defmodule StreamProcessor do
  use Application

  @impl true
  def start(_type, _args) do
    IO.inspect("The Application has started")
    url1 = "http://localhost:4000/tweets/1"
    url2 = "http://localhost:4000/tweets/2"
    engagement = "Engagement"
    sentiment = "Sentiment"
    retweet = "Retweet"

    children = [
      %{
        id: EngagementLoadBalancer,
        start: {EngagementAnalysis.LoadBalancer, :start_module, []}
      },
      %{
        id: RetweetLoadBalancer,
        start: {RetweetExtracting.LoadBalancer, :start_module, []}
      },
      %{
        id: SentimentLoadBalancer,
        start: {SentimentAnalysis.LoadBalancer, :start_module, []}
      },
      %{
        id: EngagementPoolSupervisor,
        start: {EngagementAnalysis.PoolSupervisor, :start_module, []}
      },
      %{
        id: RetweetPoolSupervisor,
        start: {RetweetExtracting.PoolSupervisor, :start_module, []}
      },
      %{
        id: SentimentPoolSupervisor,
        start: {SentimentAnalysis.PoolSupervisor, :start_module, []}
      },
      %{
        id: EngagementAutoScaler,
        start: {EngagementAnalysis.AutoScaler, :start_module, []}
      },
      %{
        id: RetweetAutoScaler,
        start: {RetweetExtracting.AutoScaler, :start_module, []}
      },
      %{
        id: SentimentAutoScaler,
        start: {SentimentAnalysis.AutoScaler, :start_module, []}
      },
      %{
        id: Aggregator,
        start: {Aggregator, :start_module, []}
      },
      %{
        id: BatcherStats,
        start: {BatcherStats, :start_module, []}
      },
      %{
        id: Batcher,
        start: {Batcher, :start_module, []}
      },
      %{
        id: Router,
        start: {Router, :start_module, []}
      },
      %{
        id: StreamReader1,
        start: {StreamReader, :start_connection, [url1]}
      },
      %{
        id: StreamReader2,
        start: {StreamReader, :start_connection, [url2]}
      },
    ]

    opts = [strategy: :one_for_one, max_restarts: 100, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
