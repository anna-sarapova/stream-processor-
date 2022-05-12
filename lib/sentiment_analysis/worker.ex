defmodule SentimentAnalysis.Worker do
  use GenServer
  require Logger

  def start_module(index) do
    GenServer.start_link(__MODULE__, %{}, nme: String.to_atom("SentimentalPinguin#{index}"))
  end

  def receive_tweets(pid, id, tweet) do
    if tweet == "{\"message\": panic}" do
      Process.exit(pid, :normal)
    else
      GenServer.cast(pid, {:process_tweet, id, tweet})
    end
  end

  defp parse_words(tweet_msg) do
    punctuation = [",", ".", ":", "?", "!"]
    tweet_msg
    |> String.replace(punctuation, "")
    |> String.split(" ", trim: true)
  end

  defp calculate_sentiment_score(tweet_words) do
    tweet_words
    |> Enum.reduce(0, fn tweet_word, acc -> SentimentAnalysis.EmotionalScore.get_value(tweet_word) + acc end)
    |> Kernel./(length(tweet_words))
  end

  defp parse_tweet(id, tweet_data) do
    tweet_msg = tweet_data["message"]["tweet"]["text"]
    sentiment_score = tweet_msg
    |> parse_words()
    |> calculate_sentiment_score()
    Aggregator.add_sentiment_score(id, sentiment_score)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:process_tweet, id, tweet}, state) do
    {:ok, tweet_data} = Poison.decode(tweet)
    parse_tweet(id, tweet_data)
    {:noreply, state}
  end

end
