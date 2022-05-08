defmodule EngagementAnalysis.Worker do
  use GenServer
  require Logger

  def start_module(index) do
    GenServer.start_link(__MODULE__, index, name: String.to_atom("EngagementWorker#{index}"))
  end

  def receive_tweets(pid, id, tweet) do
    if tweet == "{\"message\": panic}" do
      Process.exit(pid, :normal)
      #     IO.inspect("Worker: The process #{inspect(pid)} is killed")
    else
      GenServer.cast(pid, {:process_tweet, id, tweet})
    end
  end

  def init(index) do
    IO.inspect("Worker: Pinguin #{index}")
    {:ok, index}
  end

  def handle_cast({:process_tweet, id, tweet}, index) do
    {:ok, tweet_data} = Poison.decode(tweet)
    follower_count = tweet_data["message"]["tweet"]["user"]["followers_count"]
#    Logger.info("Worker: Pinguin #{inspect(index)} says #{inspect(String.slice(tweet, 0..30))}", ansi_color: :green)
#    Logger.info("Worker: Pinguin #{inspect(index)} says #{inspect(follower_count)}", ansi_color: :cyan)
    {:noreply, index}
  end
end
