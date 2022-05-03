defmodule StreamReader do

  def start_connection(url) do
    IO.puts("The Stream Reader has started")
    # links every tweet(from get_tweet) to a process
    link_process = spawn_link(__MODULE__, :get_tweet, [])
    # start the module EventSource
    {:ok,pid} = EventsourceEx.new(url, stream_to: link_process)

    # check if connection is still valid
    spawn_link(__MODULE__, :check_connection, [url, link_process, pid])
    {:ok, self()}
  end

  def get_tweet() do
    receive do
      tweet ->
        Router.get_tweets(tweet.data)
    end
    get_tweet()
  end

  def check_connection(url, link_process, pid) do
    Process.monitor(pid)
    receive do
      _err ->
        IO.puts("Restart connection")
        {:ok,new_pid} = EventsourceEx.new(url, stream_to: link_process)

        # check if connection is still valid
        spawn_link(__MODULE__, :check_connection, [url, link_process, new_pid])
    end
  end
end

