defmodule RetweetExtracting.Worker do
  use GenServer
  require Logger

  def start_module(index) do
    GenServer.start_link(__MODULE__, %{}, name: String.to_atom("RetweetPinguin#{index}"))
  end

  def receive_tweets(pid, tweet) do
    if tweet == "{\"message\": panic}" do
      Process.exit(pid, :normal)
    else
      GenServer.cast(pid, {:forward_tweet, tweet})
    end
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:forward_tweet, tweet}, state) do
    {:ok, tweet_data} = Poison.decode(tweet)
    tweet_info = tweet_data["message"]["tweet"]
    retweet_status = Map.has_key?(tweet_info, "retweeted_status")
    if retweet_status do
      original_tweet = tweet_data["message"]["tweet"]["retweeted_status"]
      new_tweet_data = %{"message" => %{"tweet" => original_tweet}}
      {:ok, new_tweet} = Poison.encode(new_tweet_data)
      Router.get_tweets(new_tweet)
    end
    {:noreply, state}
  end

end
