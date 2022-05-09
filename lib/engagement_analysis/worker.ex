defmodule EngagementAnalysis.Worker do
  use GenServer
  require Logger

  def start_module(index) do
    GenServer.start_link(__MODULE__, index, name: String.to_atom("EngagementPinguin#{index}"))
  end

  def receive_tweets(pid, id, tweet) do
    if tweet == "{\"message\": panic}" do
      Process.exit(pid, :normal)
      #     IO.inspect("Worker: The process #{inspect(pid)} is killed")
    else
      GenServer.cast(pid, {:process_tweet, id, tweet})
    end
  end

  defp calculate_engagement_score(favourites_count, 0, retweet_count) do
    favourites_count + retweet_count
  end

  defp calculate_engagement_score(favourites_count, follower_count, retweet_count) do
    (favourites_count + retweet_count) / follower_count
  end

  def init(index) do
    IO.inspect("Worker: Pinguin #{index}")
    {:ok, index}
  end

  def handle_cast({:process_tweet, id, tweet}, index) do
    {:ok, tweet_data} = Poison.decode(tweet)
    favourites_count = tweet_data["message"]["tweet"]["favorite_count"]
#    Logger.info("Worker: Pinguin #{inspect(index)} has favourites: #{inspect(favourites_count)}", ansi_color: :light_blue)
    follower_count = tweet_data["message"]["tweet"]["user"]["followers_count"]
#    Logger.info("Worker: Pinguin #{inspect(index)} has followers: #{inspect(follower_count)}", ansi_color: :light_green)
    retweet_count = tweet_data["message"]["tweet"]["retweet_count"]
#    Logger.info("Worker: Pinguin #{inspect(index)} has retweet: #{inspect(retweet_count)}", ansi_color: :light_magenta)
    engagement_score = calculate_engagement_score(favourites_count, follower_count, retweet_count)
    Logger.info("Worker: Pinguin #{inspect(index)} has engagement-score: #{inspect(engagement_score)}", ansi_color: :light_cyan)
    {:noreply, index}
  end
end
