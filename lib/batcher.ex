defmodule Batcher do
  use GenServer
  require Logger

  @records_size 99
  @timer 1000

  def start_module() do
    IO.inspect("Starting Batcher")
    {:ok, mongo_db} = Mongo.start_link(url: "mongodb://localhost:27017/Stream_Processor")
    timer_ref =  restart_timer()
    GenServer.start_link(__MODULE__, %{batch: [], mongo_db: mongo_db, records_per_interval: 0, timer_ref: timer_ref}, name: __MODULE__)
  end

  def receive_record(record) do
    GenServer.cast(__MODULE__, {:add_in_state, record})
  end

  def restart_timer() do
    Process.send_after(self(), :reset_timer, @timer)
  end

  def send_to_database(records, mongo_db) do
    batch_size = Kernel.length(records)
    Mongo.insert_many(mongo_db, "tweets", get_tweet(records))
    Mongo.insert_many(mongo_db, "user", get_user(records))
    Logger.info("Batcher: the records were sent, batch size #{inspect(batch_size)}", ansi_color: :light_blue)
  end

  def get_user(records) do
    Enum.map(records, fn record -> record.user end)
  end

  def get_tweet(records) do
    Enum.map(records, fn record -> record.tweet_data end)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_in_state, record}, state) do
    records_list = [record | state.batch]
    record_counter = state.records_per_interval + 1
    case state.records_per_interval >= @records_size do
      true ->
        send_to_database(records_list, state.mongo_db)
        Process.cancel_timer(state.timer_ref)
        timer_ref = restart_timer()
        {:noreply, %{batch: [], mongo_db: state.mongo_db, records_per_interval: 0, timer_ref: timer_ref}}
      false ->
        {:noreply, %{batch: records_list, mongo_db: state.mongo_db, records_per_interval: record_counter , timer_ref: state.timer_ref}}
    end
  end

  def handle_info(:reset_timer, state) do
    if Kernel.length(state.batch) == 0 do
      timer_ref = restart_timer()
      {:noreply, %{batch: [], mongo_db: state.mongo_db, records_per_interval: 0, timer_ref: timer_ref}}
    else
      send_to_database(state.batch, state.mongo_db)
      timer_ref = restart_timer()
      {:noreply, %{batch: [], mongo_db: state.mongo_db, records_per_interval: 0, timer_ref: timer_ref}}
    end
  end

end
