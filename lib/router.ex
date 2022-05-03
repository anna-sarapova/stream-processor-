defmodule Router do
  use GenServer
  require Logger

  def start_module() do
    IO.inspect("Starting Router")
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def get_tweets(tweet) do
    GenServer.cast(__MODULE__, {:receive_tweets, tweet})
  end



  # Server start_module callback
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:receive_tweets, tweet}, state) do
    IO.inspect("Router: #{inspect(tweet)}")

    {:noreply, state}
  end
end
